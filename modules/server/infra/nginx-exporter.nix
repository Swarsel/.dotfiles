{
  flake.modules.nixos.nginx-exporter =
    {
      lib,
      config,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "nginx-exporter";
          port = 9113;
        })
        servicePort
        serviceName
        ;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];

        globals = {
          services.${serviceName}.extraConfig = {
            port = servicePort;
          };
        };

        topology.self.services.${serviceName} = {
          name = serviceName;
          icon = "services.prometheus";
        };

        services.nginx.statusPage = true;

        services.prometheus.exporters.nginx = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = servicePort;
        };

        environment.etc."alloy/config.alloy".text = lib.mkIf config.services.alloy.enable (
          lib.mkAfter ''
            prometheus.scrape "nginx" {
              targets    = [{"__address__" = "127.0.0.1:${toString servicePort}"}]
              forward_to = [prometheus.remote_write.mimir.receiver]
              job_name   = "nginx"
            }
          ''
        );
      };
    }

  ;
}
