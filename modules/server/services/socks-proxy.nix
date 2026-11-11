{
  flake.modules.nixos.socks-proxy =
    {
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
          domain = "socks-proxy.${globals.domains.main}";
          name = "socks-proxy";
          port = 1080;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceName
        servicePort
        ;
      inherit (confLib.static)
        homeServiceAddress
        isHome
        webProxy
        ;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
          info = "socks5://${serviceAddress}:${toString servicePort}";
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
            extra.extraConfig.port = servicePort;
          };
          monitoring.tcp = confLib.mkTcpMonitoring { inherit serviceName servicePort; };
          networks."${webProxy}-wgProxy".hosts.${config.node.name}.firewallRuleForNode =
            lib.genAttrs globals.general.socksProxyConsumers
              (_: {
                allowedTCPPorts = [ servicePort ];
              });
        };
        users.persistentIds.microsocks = confLib.mkIds 988;
        services.microsocks = {
          enable = true;
          ip = "0.0.0.0";
          port = servicePort;
        };
      };
    };
}
