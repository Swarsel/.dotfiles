{
  flake.modules.nixos.socks-proxy =
    {
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
        serviceName
        servicePort
        ;
      inherit (confLib.static)
        homeServiceAddress
        isHome
        webProxy
        ;

      consumer = "moonside";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          icon = "services.not-available";
          info = "https://${serviceAddress}";
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
              serviceName
              ;
            extra.extraConfig.port = servicePort;
            serviceDomain = "socks-proxy.${globals.domains.main}";
          };
          networks."${webProxy}-wgProxy".hosts.${config.node.name}.firewallRuleForNode.${consumer}.allowedTCPPorts =
            [
              servicePort
            ];
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
