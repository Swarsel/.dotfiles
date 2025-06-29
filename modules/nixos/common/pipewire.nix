{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.pipewire = lib.mkEnableOption "pipewire config";
  config = lib.mkIf config.swarselsystems.modules.pipewire {
    security.rtkit.enable = true; # this is required for pipewire real-time access

    services.pipewire = {
      enable = true;
      package = pkgs.stable.pipewire;
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
