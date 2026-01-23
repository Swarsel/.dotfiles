{ self, lib, config, pkgs, confLib, ... }:
let
  inherit (config.swarselsystems) sopsFile;
  inherit (confLib.gen { name = "mpd"; port = 3254; }) servicePort serviceName serviceUser serviceGroup;
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

    topology.self.services.${serviceName}.info = "http://localhost:${builtins.toString servicePort}";

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = "/var/lib/${serviceName}"; user = "mpd"; group = "mpd"; }];
    };

    services.${serviceName} = {
      enable = true;
      openFirewall = true;
      settings = {
        music_directory = "/storage/Music";
        bind_to_address = "any";
        port = servicePort;
      };
      user = serviceUser;
      group = serviceGroup;
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
