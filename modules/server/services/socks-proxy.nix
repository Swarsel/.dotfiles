{
  flake.modules.nixos.socks-proxy =
    {
      lib,
      config,
      globals,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "socks-proxy";
          port = 1080;
          domain = "socks-proxy.${globals.domains.main}";
        })
        servicePort
        serviceName
        serviceAddress
        proxyAddress4
        proxyAddress6
        ;
      inherit (confLib.static)
        isHome
        webProxy
        homeServiceAddress
        ;

      consumer = "moonside";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];

        users.persistentIds.microsocks = confLib.mkIds 988;

        services.microsocks = {
          enable = true;
          ip = "0.0.0.0";
          port = servicePort;
        };

        globals.services = confLib.mkServiceGlobal {
          inherit
            serviceName
            proxyAddress4
            proxyAddress6
            isHome
            serviceAddress
            homeServiceAddress
            ;
          serviceDomain = "socks-proxy.${globals.domains.main}";
          extra.extraConfig.port = servicePort;
        };

        globals.networks."${webProxy}-wgProxy".hosts.${config.node.name}.firewallRuleForNode.${consumer}.allowedTCPPorts = [
          servicePort
        ];
      };
    };
}
