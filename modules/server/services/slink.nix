{
  flake.modules.nixos.slink =
    {
      self,
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/slink";
          name = "slink";
          port = 3000;
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
        scannerDropRules
        webProxy
        ;

      containerRev = "sha256:98b9442696f0a8cbc92f0447f54fa4bad227af5dcfd6680545fedab2ed28ddd9";
    in
    {
      imports = [
        self.modules.nixos.podman
      ];
      config = {
        swarselsystems.enabledServerModules = [ "slink" ];
        topology.nodes.${topologyContainerName}.services.${serviceName} = {
          icon = "services.not-available";
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
            expectedBodyRegex = "OK";
            hostHeader = serviceDomain;
            path = "/api/health";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        # networking.firewall.allowedTCPPorts = [ servicePort ];
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          { directory = serviceDir; }
        ];
        virtualisation.oci-containers.containers.${serviceName} = {
          environment = {
            "IMAGE_MAX_SIZE" = "50M";
            "ORIGIN" = "https://${serviceDomain}";
            "STORAGE_PROVIDER" = "local";
            "TZ" = config.repo.secrets.common.location.timezone;
            "USER_APPROVAL_REQUIRED" = "true";
          };
          extraOptions = [
            "--health-cmd=wget -O - -q http://127.0.0.1:${builtins.toString servicePort}/api/health | grep -q OK"
            "--health-interval=30s"
            "--health-retries=3"
            "--health-timeout=10s"
            "--health-start-period=60s"
            "--health-on-failure=kill"
          ];
          image = "anirdev/slink@${containerRev}";
          ports = [ "${builtins.toString servicePort}:${builtins.toString servicePort}" ];
          volumes = [
            "${serviceDir}/var/data:/app/var/data"
            "${serviceDir}/images:/app/slink/images"
          ];
        };
        systemd.tmpfiles.settings."12-slink" = builtins.listToAttrs (
          map
            (path: {
              name = "${serviceDir}/${path}";
              value.d = {
                group = "root";
                mode = "0750";
                user = "root";
              };
            })
            [
              "var/data"
              "images"
            ]
        );
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
                    "/".proxyPass = "http://${serviceName}";
                    "/image" = {
                      bypassAuth = true;
                      proxyPass = "http://${serviceName}";
                      setOauth2Headers = false;
                    };
                  };
                  oauth2 = {
                    enable = true;
                    allowedGroups = [ "slink_access" ];
                  };
                  useACMEHost = globals.domains.main;
                };
              };
            };
          in
          lib.mkMerge [
            { ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; }; }
            { ${webProxy}.services.nginx = genNginx serviceAddress scannerDropRules; }
            {
              ${homeWebProxy}.services.nginx = lib.mkIf isHome (
                genNginx homeServiceAddress (scannerDropRules + nginxAccessRules)
              );
            }
          ];

      };
    }

  ;
}
