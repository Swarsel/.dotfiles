{ self, lib, config, pkgs, ... }:
let
  servicePort = 3254;
  serviceUser = "mpd";
  serviceGroup = serviceUser;
  serviceName = "mpd";
in
{
  options.swarselsystems.modules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server.${serviceName} {
    users = {
      groups = {
        mpd = { };
      };

      users = {
        ${serviceUser} = {
          isSystemUser = true;
          group = serviceGroup;
          extraGroups = [ "audio" "utmp" ];
        };
      };
    };

    sops = {
      secrets.mpdpass = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
    };

    environment.systemPackages = with pkgs; [
      pciutils
      alsa-utils
      mpv
    ];

    topology.self.services.${serviceName} = {
      name = lib.toUpper serviceName;
      info = "http://localhost:${builtins.toString servicePort}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

    services.${serviceName} = {
      enable = true;
      musicDirectory = "/media";
      user = serviceUser;
      group = serviceGroup;
      network = {
        port = servicePort;
        listenAddress = "any";
      };
      credentials = [
        {
          passwordFile = config.sops.secrets.mpdpass.path;
          permissions = [
            "read"
            "add"
            "control"
            "admin"
          ];
        }
      ];
    };
  };

}
