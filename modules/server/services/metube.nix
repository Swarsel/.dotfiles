{
  flake.modules.nixos.metube =
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
          dir = "/var/lib/metube";
          name = "metube";
          port = 8087;
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

      containerRev = "sha256:df929ef2453fd75c1f1cbd8dafb309ee03ff18d8705c7c1e01642b1202d4a650";
      containerPort = 8081;
      serviceId = 935;
    in
    {
      imports = [
        self.modules.nixos.podman
      ];
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.nodes.${topologyContainerName}.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}";
          name = "MeTube";
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
            expectedBodyRegex = "MeTube";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
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
        virtualisation.oci-containers.containers.${serviceName} = {
          environment = {
            DOWNLOAD_DIR = "/downloads";
            GID = builtins.toString serviceId;
            STATE_DIR = "/state";
            UID = builtins.toString serviceId;
          };
          image = "ghcr.io/alexta69/metube@${containerRev}";
          ports = [ "${builtins.toString servicePort}:${builtins.toString containerPort}" ];
          volumes = [
            "${serviceDir}/downloads:/downloads"
            "${serviceDir}/state:/state"
          ];
        };
        systemd.services."podman-${serviceName}" = {
          preStart = lib.mkAfter ''
            install -d -o ${serviceUser} -g ${serviceGroup} -m 0750 ${serviceDir}/downloads ${serviceDir}/state
          '';
          unitConfig.RequiresMountsFor = [ serviceDir ];
        };
        nodes =
          let
            genNginx = toAddress: extraConfig: {
              upstreams.${serviceName}.servers = {
                "${toAddress}:${builtins.toString servicePort}" = { };
              };
              virtualHosts.${serviceDomain} = {
                inherit extraConfig;
                acmeRoot = null;
                forceSSL = true;
                locations."/" = {
                  extraConfig = ''
                    client_max_body_size 0;
                  '';
                  proxyPass = "http://${serviceName}";
                  proxyWebsockets = true;
                };
                oauth2 = {
                  enable = true;
                  allowedGroups = [ "${serviceName}_access" ];
                };
                useACMEHost = globals.domains.main;
              };
            };
          in
          lib.mkMerge [
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
