{
  flake.modules.nixos.mosquitto =
    {
      config,
      lib,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/mosquitto";
          name = "mosquitto";
          port = 1883;
        })
        serviceDir
        serviceGroup
        serviceName
        servicePort
        serviceUser
        ;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName}.info = "mqtt://127.0.0.1:${toString servicePort}";
        globals.monitoring = {
          tcp = confLib.mkTcpMonitoring { inherit serviceName servicePort; };
          systemd = confLib.mkSystemdMonitoring {
            inherit serviceName;
            unit = "${serviceName}.service";
          };
        };
        services.${serviceName} = {
          enable = true;
          listeners = [
            {
              acl = [ "topic readwrite #" ];
              address = "127.0.0.1";
              omitPasswordAuth = true;
              port = servicePort;
              settings.allow_anonymous = true;
            }
          ];
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            group = serviceGroup;
            user = serviceUser;
          }
        ];
      };
      key = "swarsel/server/mosquitto";
    };
}
