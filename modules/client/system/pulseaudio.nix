{
  flake.modules.nixos.pulseaudio = { config, pkgs, lib, ... }: {
    config = {
      services.pulseaudio = {
        enable = lib.mkIf (!config.services.pipewire.enable) true;
        package = pkgs.pulseaudioFull;
      };
    };
  };
}
