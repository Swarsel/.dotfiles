{
  flake.modules.nixos.ipmi-exporter =
    {
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "ipmi-exporter";
          port = 9290;
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
        services.prometheus.exporters.ipmi = {
          enable = true;
          configFile = (pkgs.formats.yaml { }).generate "ipmi.yml" {
            modules.default = {
              collectors = [
                "bmc"
                "chassis"
                "dcmi"
                "ipmi"
                "sel"
              ];
              custom_args.ipmi = [
                "--sdr-cache-directory"
                "/var/cache/prometheus-ipmi-exporter"
              ];
              driver = "OPENIPMI";
            };
          };
          group = "root";
          listenAddress = "127.0.0.1";
          port = servicePort;
          user = "root";
        };
        boot.kernelModules = [
          "ipmi_devintf"
          "ipmi_si"
        ];
        environment.etc."alloy/config.alloy".text = confLib.mkAlloyScrape {
          name = "ipmi";
          port = servicePort;
          scrapeSettings = {
            scrape_interval = "60s";
            scrape_timeout = "30s";
          };
        };
        systemd.services.prometheus-ipmi-exporter.serviceConfig = {
          CacheDirectory = "prometheus-ipmi-exporter";
          DeviceAllow = [ "char-ipmidev rw" ];
          DynamicUser = false;
          PrivateDevices = false;
        };
        nodes.${globals.general.monitoringServer}.services.grafana.provision.alerting.rules.settings.groups =
          [
            {
              folder = "Infrastructure";
              interval = "1m";
              name = "ipmi";
              orgId = 1;
              rules = [
                (confLib.mkGrafanaAlertRule {
                  expr = "max by (host, name, type) (ipmi_sensor_state)";
                  op = "gt";
                  summary = "{{ $labels.host }}: IPMI {{ $labels.type }} sensor {{ $labels.name }} is in critical state";
                  threshold = 1;
                  title = "IPMI sensor critical";
                  uid = "ipmi_sensor_critical";
                })
              ];
            }
          ];
      };
    };
}
