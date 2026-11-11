{
  flake.modules.nixos.smartctl-exporter =
    {
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "smartctl-exporter";
          port = 9633;
        })
        serviceName
        servicePort
        ;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          icon = "services.prometheus";
          name = serviceName;
        };
        users.persistentIds.smartctl-exporter-access = confLib.mkIds 947;
        services.prometheus.exporters.smartctl = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = servicePort;
        };
        environment.etc."alloy/config.alloy".text = confLib.mkAlloyScrape {
          name = "smartctl";
          port = servicePort;
          scrapeSettings.scrape_interval = "60s";
        };
      };
    };
}
