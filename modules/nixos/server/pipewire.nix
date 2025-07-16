{ lib, config, ... }:
{
  config = lib.mkIf (config?swarselmodules.server.mpd || config?swarselmodules.server.navidrome) {

    security.rtkit.enable = true; # this is required for pipewire real-time access

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
