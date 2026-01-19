{ lib, config, confLib, ... }:
{
  config = lib.mkIf (config.swarselmodules.server.mpd || config.swarselmodules.server.navidrome) {

    security.rtkit.enable = true; # this is required for pipewire real-time access

    users.persistentIds.rtkit = confLib.mkIds 996;

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = "/var/lib/pipewire"; user = "pipewire"; group = "pipewire"; }];
    };

    services.pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
      audio.enable = true;
      wireplumber.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
    };
  };

}
