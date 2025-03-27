{ config, pkgs, lib, ... }: {

  services.pulseaudio = {
    enable = lib.mkIf (!config.services.pipewire.enable) true;
    package = pkgs.pulseaudioFull;
  };

}
