{
  flake.modules.nixos.smartctl-exporter =
    { lib, config, confLib, ... }:
    let
      inherit (confLib.gen { name = "smartctl-exporter"; port = 9633; })
        servicePort serviceName;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];

        users.persistentIds.smartctl-exporter-access = confLib.mkIds 947;

        globals = {
          services.${serviceName}.extraConfig = {
            port = servicePort;
          };
        };

        topology.self.services.${serviceName} = {
          name = serviceName;
          icon = "services.prometheus";
        };

        services.prometheus.exporters.smartctl = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = servicePort;
        };

        environment.etc."alloy/config.alloy".text = lib.mkIf config.services.alloy.enable (lib.mkAfter ''
          prometheus.scrape "smartctl" {
            targets         = [{"__address__" = "127.0.0.1:${toString servicePort}"}]
            forward_to      = [prometheus.remote_write.mimir.receiver]
            job_name        = "smartctl"
            scrape_interval = "60s"
          }
        '');
      };
    }

  ;
}
