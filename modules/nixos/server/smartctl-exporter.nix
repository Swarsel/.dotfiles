{ confLib, ... }:
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

    services.prometheus.exporters.smartctl = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = servicePort;
    };
  };
}
