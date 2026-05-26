{ confLib, ... }:
let
  inherit (confLib.gen { name = "zfs-exporter"; port = 9134; })
    servicePort serviceName;
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

    services.prometheus.exporters.zfs = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = servicePort;
    };
  };
}
