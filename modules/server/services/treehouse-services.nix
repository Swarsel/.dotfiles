{
  flake.modules.nixos.treehouse-services =
    {
      inputs,
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit (confLib.static)
        homeWebProxy
        idmServer
        nginxAccessRules
        webProxy
        ;

      host = "treehouse";
      hostIn = network: globals.networks.${network}.hosts.${host};
      wgNetwork = ifName: "${globals.wireguard.${ifName}.netConfigPrefix}-${ifName}";

      proxyAddress4 = globals.hosts.${webProxy}.wanAddress4;
      proxyAddress6 = globals.hosts.${webProxy}.wanAddress6;
      serviceAddress = (hostIn (wgNetwork "wgProxy")).ipv4;
      homeServiceAddress = (hostIn (wgNetwork "wgHome")).ipv4;

      webServicePorts = {
        comfyui = 8188;
        open-webui = 8080;
      };
      domainOf = serviceName: config.repo.secrets.common.services.domains.${serviceName};

      wolfDomain = domainOf "wolf";
      homeVlanHost = globals.networks.home-lan.vlans.home.hosts.${host};
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "treehouse-services" ];
        globals = {
          services = lib.mkMerge (
            lib.forEach (lib.attrNames webServicePorts) (
              serviceName:
              confLib.mkServiceGlobal {
                inherit
                  homeServiceAddress
                  proxyAddress4
                  proxyAddress6
                  serviceAddress
                  serviceName
                  ;
                isHome = true;
                serviceDomain = domainOf serviceName;
              }
            )
          );
          dns = lib.mkMerge (
            lib.forEach (lib.attrNames webServicePorts) (
              serviceName: confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; }
            )
            ++ lib.optional (globals.roaming.${host}.location == "home") {
              ${lib.swarselsystems.getBaseDomain wolfDomain}.subdomainRecords.${lib.swarselsystems.getSubDomain wolfDomain} =
                inputs.dns.lib.combinators.host homeVlanHost.ipv4 null;
            }
          );
        };
        nodes = lib.mkMerge (
          lib.concatLists (
            lib.mapAttrsToList (serviceName: servicePort: [
              { ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; }; }
              {
                ${webProxy}.services.nginx = confLib.genNginx {
                  inherit serviceAddress serviceName servicePort;
                  maxBody = 0;
                  oauth2 = true;
                  oauth2Groups = [ "${serviceName}_access" ];
                  proxyWebsockets = true;
                  serviceDomain = domainOf serviceName;
                };
              }
              {
                ${homeWebProxy}.services.nginx = confLib.genNginx {
                  inherit serviceName servicePort;
                  extraConfig = nginxAccessRules;
                  maxBody = 0;
                  oauth2 = true;
                  oauth2Groups = [ "${serviceName}_access" ];
                  proxyWebsockets = true;
                  serviceAddress = homeServiceAddress;
                  serviceDomain = domainOf serviceName;
                };
              }
            ]) webServicePorts
          )
        );
      };
    };
}
