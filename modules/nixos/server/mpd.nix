{ self, lib, config, pkgs, ... }:
let
  inherit (config.swarselsystems) sopsFile;

  servicePort = 3254;
  serviceUser = "mpd";
  serviceGroup = serviceUser;
  serviceName = "mpd";
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {
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
      secrets.mpd-pw = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
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
          passwordFile = config.sops.secrets.mpd-pw.path;
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
