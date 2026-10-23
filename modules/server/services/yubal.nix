{
  flake.modules.nixos.yubal =
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
          dir = "/var/lib/yubal";
          name = "yubal";
          port = 8086;
        })
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
        ;

      containerRev = "sha256:1447663d19eb69e4c6c6d274e979a99c4013a7d0a7666ca1bf2127612cd639eb";
      containerPort = 8000;
      musicDir = "/storage/Music/${serviceName}";
      serviceId = 1003;
    in
    {
      imports = [
        self.modules.nixos.podman
      ];
      config = {
        swarselsystems.enabledServerModules = [ "yubal" ];
        topology.nodes.${topologyContainerName}.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}";
          name = lib.swarselsystems.toCapitalized serviceName;
        };
        globals = {
          services.${serviceName} = {
            inherit isHome;
            domain = serviceDomain;
          };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "yubal";
          };
          networks = confLib.mkDualFirewallRules {
            forWebProxy = false;
            tcpPorts = [ servicePort ];
          };
        };
        users = {
          users.${serviceUser} = {
            extraGroups = [ "users" ];
            group = serviceGroup;
            isSystemUser = true;
          };
          groups.${serviceGroup} = { };
          persistentIds.${serviceName} = confLib.mkIds serviceId;
        };
        environment.persistence =
          let
            persistedDirs = [
              {
                directory = serviceDir;
                group = serviceGroup;
                mode = "0750";
                user = serviceUser;
              }
            ];
          in
          {
            "/persist".directories = lib.mkIf (
              config.swarselsystems.isImpermanence && !config.swarselsystems.isMicroVM
            ) persistedDirs;
            "/state".directories = lib.mkIf config.swarselsystems.isMicroVM persistedDirs;
          };
        virtualisation.oci-containers.containers.${serviceName} = {
          environment = {
            PGID = builtins.toString serviceId;
            PUID = builtins.toString serviceId;
            YUBAL_PORT = builtins.toString containerPort;
            YUBAL_TZ = config.repo.secrets.common.location.timezone;
          };
          image = "ghcr.io/guillevc/yubal@${containerRev}";
          ports = [ "${builtins.toString servicePort}:${builtins.toString containerPort}" ];
          volumes = [
            "${serviceDir}/config:/app/config"
            "${musicDir}:/app/data"
          ];
        };
        systemd.services."podman-${serviceName}" = {
          preStart = lib.mkAfter ''
            install -d -o ${serviceUser} -g ${serviceGroup} -m 0750 ${serviceDir}/config
            install -d -o ${serviceUser} -g users -m 2775 ${musicDir}
          '';
          unitConfig.RequiresMountsFor = [
            serviceDir
            musicDir
          ];
        };
        nodes = lib.mkMerge [
          { ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; }; }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome {
              upstreams.${serviceName}.servers = {
                "${homeServiceAddress}:${builtins.toString servicePort}" = { };
              };
              virtualHosts.${serviceDomain} = {
                acmeRoot = null;
                extraConfig = nginxAccessRules;
                forceSSL = true;
                locations = {
                  "/" = {
                    extraConfig = ''
                      client_max_body_size 0;
                    '';
                    proxyPass = "http://${serviceName}";
                  };
                  "/api" = {
                    bypassAuth = true;
                    proxyPass = "http://${serviceName}";
                    setOauth2Headers = false;
                  };
                };
                oauth2 = {
                  enable = true;
                  allowedGroups = [ "${serviceName}_access" ];
                };
                useACMEHost = globals.domains.main;
              };
            };
          }
        ];

      };
    }

  ;
}
