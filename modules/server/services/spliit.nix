{
  flake.modules.nixos.spliit =
    {
      self,
      root,
      config,
      lib,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "spliit";
          port = 8089;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
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
        webProxy
        ;

      containerRev = "sha256:cfaf0f84ef4f11cd3e4c46329039a0f1f51a7d7bf8cc218bf7c1b366e58a99f1";
      containerPort = 3000;
      postgresSocketDir = "/run/postgresql";
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
            expectedBodyRegex = ''"status":\s*"healthy"'';
            path = "/api/health";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets."${serviceName}-db-password" = {
            owner = config.systemd.services.postgresql.serviceConfig.User;
            rekey.generator.script = "alnum";
          };
          templates."${serviceName}-env".content =
            let
              databaseUrl = "postgresql://${serviceName}:${
                config.sops.placeholder."${serviceName}-db-password"
              }@localhost/${serviceName}?host=${postgresSocketDir}";
            in
            ''
              POSTGRES_PRISMA_URL=${databaseUrl}
              POSTGRES_URL_NON_POOLING=${databaseUrl}
            '';
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
        virtualisation.oci-containers.containers.${serviceName} = {
          environment = {
            BASE_URL = "https://${serviceDomain}";
            DEFAULT_CURRENCY_CODE = "EUR";
            NEXT_TELEMETRY_DISABLED = "1";
          };
          environmentFiles = [ config.sops.templates."${serviceName}-env".path ];
          image = "ghcr.io/spliit-app/spliit@${containerRev}";
          ports = [ "${builtins.toString servicePort}:${builtins.toString containerPort}" ];
          volumes = [ "${postgresSocketDir}:${postgresSocketDir}" ];
        };
        systemd.services."podman-${serviceName}" = {
          after = [ "postgresql-setup.service" ];
          requires = [ "postgresql-setup.service" ];
        };
        nodes =
          let
            genNginx =
              args:
              lib.mkMerge [
                (confLib.genNginx (
                  {
                    inherit serviceDomain serviceName servicePort;
                    oauth2 = true;
                    oauth2Groups = [ "${serviceName}_access" ];
                  }
                  // args
                ))
                {
                  virtualHosts.${serviceDomain}.locations =
                    lib.genAttrs
                      [
                        "/api/trpc/"
                        "~ ^/(?:_next/|logo/|[^/]+\\.\\w+$)"
                        "~ ^/groups/(?!create(?:/|$))[^/]+"
                      ]
                      (_: {
                        bypassAuth = true;
                        proxyPass = "http://${serviceName}";
                        setOauth2Headers = false;
                      })
                    // {
                      "~ ^/api/trpc/(?:[^/]*,)?groups\\.create(?:,|$)".proxyPass = "http://${serviceName}";
                    };
                }
              ];
          in
          lib.mkMerge [
            { ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; }; }
            { ${webProxy}.services.nginx = genNginx { inherit serviceAddress; }; }
            {
              ${homeWebProxy}.services.nginx = lib.mkIf isHome (genNginx {
                extraConfig = nginxAccessRules;
                serviceAddress = homeServiceAddress;
              });
            }
          ];

      };
    }

  ;
}
