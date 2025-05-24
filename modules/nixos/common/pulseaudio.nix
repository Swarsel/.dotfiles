{ config, pkgs, lib, ... }: {

  options.swarselsystems.modules.pulseaudio = lib.mkEnableOption "pulseaudio config";
  config = lib.mkIf config.swarselsystems.modules.pulseaudio {
    services.pulseaudio = {
      enable = lib.mkIf (!config.services.pipewire.enable) true;
      package = pkgs.pulseaudioFull;
    };
  };

}
