{
  flake.modules.nixos.shlink =
    {
      self,
      config,
      lib,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/shlink";
          name = "shlink";
          port = 8081;
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
        isHome
        nginxAccessRules
        scannerDropRules
        webProxy
        ;

      containerRev = "sha256:1a697baca56ab8821783e0ce53eb4fb22e51bb66749ec50581adc0cb6d031d7a";

      inherit (config.swarselsystems) sopsFile;
    in
    {
      imports = [
        self.modules.nixos.podman
      ];
      config = {
        swarselsystems.enabledServerModules = [ "shlink" ];
        topology.nodes.${topologyContainerName}.services.${serviceName} = {
          icon = "${self}/files/topology-images/${serviceName}.png";
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
            expectedBodyRegex = ''"status":"pass"'';
            path = "/rest/health";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets.shlink-api = { inherit sopsFile; };

          templates."shlink-env".content = ''
            INITIAL_API_KEY=${config.sops.placeholder.shlink-api}
          '';
        };
        # networking.firewall.allowedTCPPorts = [ servicePort ];
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          { directory = serviceDir; }
          { directory = "/var/lib/containers"; }
        ];
        virtualisation.oci-containers.containers.${serviceName} = {
          environment = {
            "DEFAULT_DOMAIN" = serviceDomain;
            "DEFAULT_SHORT_CODES_LENGTH" = "4";
            "PORT" = "${builtins.toString servicePort}";
            "TASK_WORKER_NUM" = "1";
            "USE_HTTPS" = "false";
            "WEB_WORKER_NUM" = "1";
          };
          environmentFiles = [
            config.sops.templates.shlink-env.path
          ];
          extraOptions = [
            ''--health-cmd=wget -O - -q http://127.0.0.1:${builtins.toString servicePort}/rest/health | grep -q '"status":"pass"' ''
            "--health-interval=30s"
            "--health-retries=3"
            "--health-timeout=10s"
            "--health-start-period=60s"
            "--health-on-failure=kill"
          ];
          image = "shlinkio/shlink@${containerRev}";
          ports = [ "${builtins.toString servicePort}:${builtins.toString servicePort}" ];
          volumes = [
            "${serviceDir}/data:/etc/shlink/data"
          ];
        };
        systemd.tmpfiles.settings."11-shlink" = builtins.listToAttrs (
          map
            (path: {
              name = "${serviceDir}/${path}";
              value.d = {
                group = "root";
                mode = "0750";
                user = "1001";
              };
            })
            [
              "data"
              "data/cache"
              "data/locks"
              "data/log"
              "data/proxies"
            ]
        );
        nodes = lib.mkMerge [
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              extraConfig = scannerDropRules;
              maxBody = 0;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = scannerDropRules + nginxAccessRules;
                maxBody = 0;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];

      };
    }

  ;
}
