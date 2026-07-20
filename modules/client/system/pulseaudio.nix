{
  flake.modules.nixos.pulseaudio =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config.services.pulseaudio = {
        enable = lib.mkIf (!config.services.pipewire.enable) true;
        package = pkgs.pulseaudioFull;
      };
    };
}
