{ config, pkgs, lib, ... }: {

  options.swarselmodules.pulseaudio = lib.mkEnableOption "pulseaudio config";
  config = lib.mkIf config.swarselmodules.pulseaudio {
    services.pulseaudio = {
      enable = lib.mkIf (!config.services.pipewire.enable) true;
      package = pkgs.pulseaudioFull;
    };
  };

}
