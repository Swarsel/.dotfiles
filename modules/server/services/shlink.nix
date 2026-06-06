{
  flake.modules.nixos.shlink =
    { self, lib, config, confLib, ... }:
    let
      inherit (confLib.gen { name = "shlink"; port = 8081; dir = "/var/lib/shlink"; }) servicePort serviceName serviceDomain serviceDir serviceAddress proxyAddress4 proxyAddress6 topologyContainerName;
      inherit (confLib.static) isHome webProxy homeWebProxy homeServiceAddress nginxAccessRules scannerDropRules;

      containerRev = "sha256:1a697baca56ab8821783e0ce53eb4fb22e51bb66749ec50581adc0cb6d031d7a";

      inherit (config.swarselsystems) sopsFile;
    in
    {
      imports = [
        self.modules.nixos.podman
      ];

      config = {
        swarselsystems.enabledServerModules = [ "shlink" ];


        sops = {
          secrets = {
            shlink-api = { inherit sopsFile; };
          };

          templates = {
            "shlink-env" = {
              content = ''
                INITIAL_API_KEY=${config.sops.placeholder.shlink-api}
              '';
            };
          };
        };

        topology.nodes.${topologyContainerName}.services.${serviceName} = {
          name = lib.swarselsystems.toCapitalized serviceName;
          info = "https://${serviceDomain}";
          icon = "${self}/files/topology-images/${serviceName}.png";
        };

        virtualisation.oci-containers.containers.${serviceName} = {
          image = "shlinkio/shlink@${containerRev}";
          environment = {
            "DEFAULT_DOMAIN" = serviceDomain;
            "PORT" = "${builtins.toString servicePort}";
            "USE_HTTPS" = "false";
            "DEFAULT_SHORT_CODES_LENGTH" = "4";
            "WEB_WORKER_NUM" = "1";
            "TASK_WORKER_NUM" = "1";
          };
          environmentFiles = [
            config.sops.templates.shlink-env.path
          ];
          ports = [ "${builtins.toString servicePort}:${builtins.toString servicePort}" ];
          volumes = [
            "${serviceDir}/data:/etc/shlink/data"
          ];
          extraOptions = [
            ''--health-cmd=wget -O - -q http://127.0.0.1:${builtins.toString servicePort}/rest/health | grep -q '"status":"pass"' ''
            "--health-interval=30s"
            "--health-retries=3"
            "--health-timeout=10s"
            "--health-start-period=60s"
            "--health-on-failure=kill"
          ];
        };

        systemd.tmpfiles.settings."11-shlink" = builtins.listToAttrs (
          map
            (path: {
              name = "${serviceDir}/${path}";
              value = {
                d = {
                  group = "root";
                  user = "1001";
                  mode = "0750";
                };
              };
            }) [
            "data"
            "data/cache"
            "data/locks"
            "data/log"
            "data/proxies"
          ]
        );

        # networking.firewall.allowedTCPPorts = [ servicePort ];

        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          { directory = serviceDir; }
          { directory = "/var/lib/containers"; }
        ];

        globals = {
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
          services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
          monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; path = "/rest/health"; expectedBodyRegex = ''"status":"pass"''; };
          dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
        };


        nodes = {
          ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; maxBody = 0; extraConfig = scannerDropRules; };
          ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; maxBody = 0; extraConfig = scannerDropRules + nginxAccessRules; serviceAddress = homeServiceAddress; });
        };

      };
    }

  ;
}
