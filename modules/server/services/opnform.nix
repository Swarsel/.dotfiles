{
  flake.modules.nixos.opnform =
    {
      self,
      root,
      config,
      lib,
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/opnform";
          name = "opnform";
          port = 8090;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
        serviceDomain
        serviceName
        servicePort
        topologyContainerName
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        idmServer
        isHome
        nginxAccessRules
        notificationMail
        webProxy
        ;

      apiRev = "sha256:e0d23f380432191871025152afff74f0dd708fe6b8b79810b46a2f24893e6f79";
      clientRev = "sha256:c1aea2ba43a07c83373f4331acdaf68ce084d5f1361bc80969ebdff86dac5ea3";
      nginxRev = "sha256:0e52bd054126cdc040b1276c0af347aeb02a41b9cfe305d6094767ac30e97949";
      redisRev = "sha256:21090af93f8324db2f0f0f4f38a7c60369d47d917e000c3423d89d2ae2883537";

      maxBodySize = "64M";
      podName = serviceName;
      podUnit = "podman-${podName}-pod.service";
      postgresSocketDir = "/run/postgresql";
      serviceUrl = "https://${serviceDomain}";
      wgProxyNet = globals.networks."${globals.wireguard.wgProxy.netConfigPrefix}-wgProxy";

      ingressConfig = pkgs.writeText "${serviceName}-ingress.conf" ''
        map $request_uri $api_uri {
          ~^/api(/.*$) $1;
          default $request_uri;
        }

        server {
          listen 80;
          root /usr/share/nginx/html/public;
          client_max_body_size ${maxBodySize};

          location / {
            proxy_http_version 1.1;
            proxy_pass http://127.0.0.1:3000;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Port $server_port;
          }

          location ^~ /api/_nuxt_icon/ {
            proxy_http_version 1.1;
            proxy_pass http://127.0.0.1:3000;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Port $server_port;
          }

          location ~/(api|open|local\/temp|forms\/assets)/ {
            try_files $uri $uri/ /index.php$is_args$args;
          }

          location ~ \.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root/index.php;
            fastcgi_param REQUEST_URI $api_uri;
            fastcgi_param HTTP_X_FORWARDED_FOR $proxy_add_x_forwarded_for;
            fastcgi_param HTTP_X_FORWARDED_HOST $http_x_forwarded_host;
            fastcgi_param HTTP_X_FORWARDED_PORT $http_x_forwarded_port;
            fastcgi_param HTTP_X_FORWARDED_PROTO $http_x_forwarded_proto;
          }

          location ~ /\. {
            deny all;
          }
        }
      '';

      apiContainer = {
        dependsOn = [ "${serviceName}-redis" ];
        environment = {
          APP_DEBUG = "false";
          APP_ENV = "production";
          APP_NAME = "OpnForm";
          APP_URL = serviceUrl;
          CACHE_DRIVER = "redis";
          DB_CONNECTION = "pgsql";
          DB_DATABASE = serviceName;
          DB_HOST = postgresSocketDir;
          DB_PORT = builtins.toString config.services.postgresql.settings.port;
          DB_USERNAME = serviceName;
          FILESYSTEM_DRIVER = "local";
          FRONT_URL = serviceUrl;
          LOCAL_FILESYSTEM_VISIBILITY = "public";
          LOG_CHANNEL = "errorlog";
          LOG_LEVEL = "info";
          MAIL_ENCRYPTION = "tls";
          MAIL_FROM_ADDRESS = notificationMail.address;
          MAIL_FROM_NAME = "OpnForm";
          MAIL_HOST = notificationMail.host;
          MAIL_MAILER = "smtp";
          MAIL_PORT = "587";
          MAIL_USERNAME = notificationMail.address;
          OPNFORM_ANONYMOUS_TELEMETRY_DISABLED = "true";
          PHP_POST_MAX_SIZE = maxBodySize;
          PHP_UPLOAD_MAX_FILESIZE = maxBodySize;
          QUEUE_CONNECTION = "redis";
          REDIS_HOST = "127.0.0.1";
          SESSION_DRIVER = "redis";
          TRUSTED_PROXIES = "${wgProxyNet.cidrv4},${wgProxyNet.cidrv6}";
        };
        environmentFiles = [ config.sops.templates."${serviceName}-api-env".path ];
        extraOptions = [ "--pod=${podName}" ];
        image = "docker.io/jhumanj/opnform-api@${apiRev}";
        volumes = [
          "${postgresSocketDir}:${postgresSocketDir}"
          "${serviceDir}/storage:/usr/share/nginx/html/storage"
        ];
      };
    in
    {
      imports = [
        self.modules.nixos.podman
        self.modules.nixos.postgresql
      ];
      config = {
        swarselsystems = {
          enabledServerModules = [ serviceName ];
          server.postgresql.rolePasswordFiles.${serviceName} =
            config.sops.secrets."${serviceName}-db-password".path;
        };
        topology.nodes.${topologyContainerName}.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
          info = serviceUrl;
          name = "OpnForm";
        };
        globals = {
          services = confLib.mkServiceGlobal {
            inherit
              homeServiceAddress
              isHome
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDomain
              serviceName
              ;
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = ''"status":\s*"ok"'';
            path = "/api/healthcheck";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets = {
            "${serviceName}-app-key".rekey.generator.script = "laravel-key";
            "${serviceName}-db-password" = {
              owner = config.systemd.services.postgresql.serviceConfig.User;
              rekey.generator.script = "alnum";
            };
            "${serviceName}-front-api-secret".rekey.generator.script = "alnum";
            "${serviceName}-jwt-secret".rekey.generator.script = "alnum";
            "kanidm-${serviceName}".rekey.keyPrefix = confLib.kanidmSecrets;
            notification-mail-pw.rekey.keyPrefix = notificationMail.keyPrefix;
          };
          templates = {
            "${serviceName}-api-env".content = ''
              APP_KEY=${config.sops.placeholder."${serviceName}-app-key"}
              DB_PASSWORD=${config.sops.placeholder."${serviceName}-db-password"}
              FRONT_API_SECRET=${config.sops.placeholder."${serviceName}-front-api-secret"}
              JWT_SECRET=${config.sops.placeholder."${serviceName}-jwt-secret"}
              MAIL_PASSWORD=${config.sops.placeholder.notification-mail-pw}
            '';
            "${serviceName}-client-env".content = ''
              NUXT_API_SECRET=${config.sops.placeholder."${serviceName}-front-api-secret"}
            '';
          };
        };
        services.postgresql = {
          ensureDatabases = [ serviceName ];
          ensureUsers = [
            {
              ensureDBOwnership = true;
              name = serviceName;
            }
          ];
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            mode = "0750";
          }
        ];
        virtualisation.oci-containers.containers = {
          ${serviceName} = {
            dependsOn = [
              "${serviceName}-api"
              "${serviceName}-client"
            ];
            extraOptions = [ "--pod=${podName}" ];
            image = "docker.io/library/nginx@${nginxRev}";
            volumes = [ "${ingressConfig}:/etc/nginx/conf.d/default.conf:ro" ];
          };
          "${serviceName}-api" = apiContainer;
          "${serviceName}-client" = {
            dependsOn = [ "${serviceName}-api" ];
            environment = {
              NUXT_PRIVATE_API_BASE = "http://127.0.0.1/api";
              NUXT_PUBLIC_API_BASE = "${serviceUrl}/api";
              NUXT_PUBLIC_APP_URL = serviceUrl;
              NUXT_PUBLIC_ENV = "production";
            };
            environmentFiles = [ config.sops.templates."${serviceName}-client-env".path ];
            extraOptions = [ "--pod=${podName}" ];
            image = "docker.io/jhumanj/opnform-client@${clientRev}";
          };
          "${serviceName}-redis" = {
            extraOptions = [ "--pod=${podName}" ];
            image = "docker.io/library/redis@${redisRev}";
            volumes = [ "${serviceDir}/redis:/data" ];
          };
          "${serviceName}-scheduler" = apiContainer // {
            cmd = [
              "php"
              "artisan"
              "schedule:work"
            ];
            dependsOn = [ "${serviceName}-api" ];
          };
          "${serviceName}-worker" = apiContainer // {
            cmd = [
              "php"
              "artisan"
              "queue:work"
            ];
            dependsOn = [ "${serviceName}-api" ];
          };
        };
        systemd.services = lib.mkMerge [
          {
            "podman-${podName}-pod" = {
              path = [ config.virtualisation.podman.package ];
              postStop = ''
                podman pod rm --force --ignore ${podName}
              '';
              preStart = ''
                install -d -m 0750 ${serviceDir}/redis ${serviceDir}/storage
                podman pod rm --force --ignore ${podName}
              '';
              script = ''
                podman pod create --name ${podName} --publish ${builtins.toString servicePort}:80
              '';
              serviceConfig = {
                RemainAfterExit = true;
                Type = "oneshot";
              };
              unitConfig.RequiresMountsFor = [ serviceDir ];
            };
            "podman-${serviceName}-api" = {
              after = [ "postgresql-setup.service" ];
              requires = [ "postgresql-setup.service" ];
            };
          }
          (lib.genAttrs
            (map (name: "podman-${name}") [
              serviceName
              "${serviceName}-api"
              "${serviceName}-client"
              "${serviceName}-redis"
              "${serviceName}-scheduler"
              "${serviceName}-worker"
            ])
            (_: {
              after = [ podUnit ];
              partOf = [ podUnit ];
              requires = [ podUnit ];
            })
          )
        ];
        nodes = lib.mkMerge [
          {
            ${idmServer} =
              lib.recursiveUpdate
                (confLib.mkKanidmOidcSystem {
                  inherit serviceDomain serviceName;
                  displayName = "OpnForm";
                  originUrl = "${serviceUrl}/auth/kanidm/callback";
                })
                {
                  services.kanidm.provision.systems.oauth2.${serviceName}.allowInsecureClientDisablePkce = true;
                };
          }
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              maxBody = maxBodySize;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                maxBody = maxBodySize;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];

      };
    }

  ;
}
