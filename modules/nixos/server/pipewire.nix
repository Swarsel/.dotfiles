{ lib, config, ... }:
{
  config = lib.mkIf (config?swarselsystems.server.mpd || config?swarselsystems.server.navidrome) {

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
