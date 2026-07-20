{
  flake.modules.nixos.snipe-it =
    {
      config,
      lib,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "snipeit";
          port = 80;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceGroup
        serviceName
        servicePort
        serviceUser
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        isHome
        nginxAccessRules
        webProxy
        ;
      # sopsFile = config.node.secretsDir + "/secrets2.yaml";
      inherit (config.swarselsystems) sopsFile;

      serviceDB = "snipeit";

      mysqlPort = 3306;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "snipeit" ];
        topology.self.services.${serviceName}.info = "https://${serviceDomain}";
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
            expectedBodyRegex = "Snipe-IT";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops.secrets.snipe-it-appkey = {
          inherit sopsFile;
          group = serviceGroup;
          mode = "0440";
          owner = serviceUser;
        };
        services.snipe-it = {
          enable = true;
          appKeyFile = config.sops.secrets.snipe-it-appkey.path;
          appURL = "https://${serviceDomain}";
          dataDir = "/var/lib/snipeit";
          database = {
            createLocally = true;
            host = "localhost";
            name = serviceDB;
            port = mysqlPort;
            user = serviceUser;
          };
          group = serviceGroup;
          hostName = serviceDomain;
          user = serviceUser;
        };
        nodes = lib.mkMerge [
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              maxBody = 0;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
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
