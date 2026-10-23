{
  flake.modules.nixos.filestash =
    {
      self,
      root,
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/filestash";
          name = "filestash";
          port = 8334;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
        serviceDomain
        serviceGroup
        serviceName
        servicePort
        serviceUser
        topologyContainerName
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        idmServer
        isHome
        nginxAccessRules
        webProxy
        ;

      inherit (config.swarselsystems) mainUser sopsFile;

      containerRev = "sha256:f595b7e8cffdad7105ad7a2fc5edad51b4de3f2b0ecf80d64d58bec3c246aab1";
      containerUid = 1000;
      serviceId = 1005;
      storageLabel = "copyparty";
      hostGateway = "host.docker.internal";
      collaboraPort = globals.services.collabora-online.extraConfig.port;
      copypartyPort = globals.services.copyparty.extraConfig.port;
    in
    {
      imports = [
        self.modules.nixos.podman
      ];
      config = {
        swarselsystems.enabledServerModules = [ "filestash" ];
        topology.nodes.${topologyContainerName}.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}";
          name = lib.swarselsystems.toCapitalized serviceName;
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
            expectedBodyRegex = ''"status":\s*"pass"'';
            path = "/healthz";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets = {
            filestash-admin-hash = { inherit sopsFile; };
            filestash-secret-key = { inherit sopsFile; };
          };
          templates.filestash-config.content = builtins.toJSON {
            auth.admin = config.sops.placeholder.filestash-admin-hash;
            connections = [
              {
                label = storageLabel;
                type = "webdav";
              }
            ];
            features = {
              office = {
                enable = true;
                filestash_server = "http://127.0.0.1:${builtins.toString servicePort}";
                office_server = "http://${hostGateway}:${builtins.toString collaboraPort}";
                rewrite_discovery_url = "https://${globals.services.collabora-online.domain}";
              };
              share.enable = true;
            };
            general = {
              force_ssl = true;
              host = serviceDomain;
              logout = "https://${serviceDomain}/oauth2/sign_out";
              secret_key = config.sops.placeholder.filestash-secret-key;
            };
            middleware = {
              attribute_mapping = {
                params = builtins.toJSON {
                  ${storageLabel} = {
                    password = config.sops.placeholder.copyparty-password;
                    type = "webdav";
                    url = "http://${hostGateway}:${builtins.toString copypartyPort}";
                    username = mainUser;
                  };
                };
                related_backend = storageLabel;
              };
              identity_provider = {
                params = builtins.toJSON {
                  strategy = "direct";
                  type = "passthrough";
                };
                type = "passthrough";
              };
            };
          };
        };
        users = {
          users.${serviceUser} = {
            group = serviceGroup;
            isSystemUser = true;
          };
          groups.${serviceGroup} = { };
          persistentIds.${serviceName} = confLib.mkIds serviceId;
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            group = serviceGroup;
            mode = "0750";
            user = serviceUser;
          }
        ];
        networking.nftables.firewall.rules.podman-to-filestash-backends = {
          allowedTCPPorts = [
            collaboraPort
            copypartyPort
          ];
          before = [ "drop" ];
          from = [ "podman" ];
          to = [ "local" ];
        };
        virtualisation.oci-containers.containers.${serviceName} = {
          environment.CONFIG_ENCRYPT = "false";
          extraOptions = [
            "--add-host=${hostGateway}:host-gateway"
            "--gidmap=0:0:${builtins.toString containerUid}"
            "--gidmap=${builtins.toString containerUid}:${builtins.toString serviceId}:1"
            "--uidmap=0:0:${builtins.toString containerUid}"
            "--uidmap=${builtins.toString containerUid}:${builtins.toString serviceId}:1"
          ];
          image = "machines/filestash@${containerRev}";
          ports = [ "${builtins.toString servicePort}:${builtins.toString servicePort}" ];
          volumes = [ "${serviceDir}:/app/data/state" ];
        };
        systemd.services."podman-${serviceName}" = {
          preStart = lib.mkAfter ''
            install -d -o ${serviceUser} -g ${serviceGroup} -m 0750 ${serviceDir}/config
            install -o ${serviceUser} -g ${serviceGroup} -m 0600 ${config.sops.templates.filestash-config.path} ${serviceDir}/config/config.json
          '';
          unitConfig.RequiresMountsFor = [ serviceDir ];
        };
        nodes =
          let
            genNginx = toAddress: extraConfig: {
              upstreams = {
                ${serviceName}.servers = {
                  "${toAddress}:${builtins.toString servicePort}" = { };
                };
              };
              virtualHosts = {
                "${serviceDomain}" = {
                  inherit extraConfig;
                  acmeRoot = null;
                  forceSSL = true;
                  locations = {
                    "/" = {
                      X-Frame-Options = "SAMEORIGIN";
                      extraConfig = ''
                        client_max_body_size 0;
                      '';
                      proxyPass = "http://${serviceName}";
                    };
                    "/api/session/auth/" = {
                      X-Frame-Options = "SAMEORIGIN";
                      proxyPass = "http://${serviceName}";
                    };
                  }
                  //
                    lib.genAttrs
                      [
                        "/api/"
                        "/assets/"
                        "/overrides/"
                        "/s/"
                      ]
                      (_: {
                        X-Frame-Options = "SAMEORIGIN";
                        bypassAuth = true;
                        extraConfig = ''
                          client_max_body_size 0;
                        '';
                        proxyPass = "http://${serviceName}";
                        setOauth2Headers = false;
                      });
                  oauth2 = {
                    enable = true;
                    allowedGroups = [ "${serviceName}_access" ];
                  };
                  useACMEHost = globals.domains.main;
                };
              };
            };
          in
          lib.mkMerge [
            (lib.optionalAttrs (globals.services ? collabora-online) {
              ${globals.services.collabora-online.extraConfig.node}.services.collabora-online = {
                aliasGroups = [ { host = "http://127.0.0.1:${builtins.toString servicePort}"; } ];
                settings.net.content_security_policy = "frame-ancestors https://${serviceDomain}";
              };
            })
            { ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; }; }
            { ${webProxy}.services.nginx = genNginx serviceAddress ""; }
            {
              ${homeWebProxy}.services.nginx = lib.mkIf isHome (genNginx homeServiceAddress nginxAccessRules);
            }
          ];

      };
    }

  ;
}
