{
  flake.modules.nixos.nginx-exporter =
    {
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "nginx-exporter";
          port = 9113;
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
        services = {
          nginx.statusPage = true;
          prometheus.exporters.nginx = {
            enable = true;
            listenAddress = "127.0.0.1";
            port = servicePort;
          };
        };
        environment.etc."alloy/config.alloy".text = confLib.mkAlloyScrape {
          name = "nginx";
          port = servicePort;
        };
      };
    };
}
