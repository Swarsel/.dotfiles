{ lib, config, outputs, ... }:
{

  options.swarselsystems.modules.darwin.general = lib.mkEnableOption "darwin config";
  config = lib.mkIf config.swarselsystems.modules.darwin.general {
    nix.settings.experimental-features = "nix-command flakes";
    nixpkgs = {
      hostPlatform = "x86_64-darwin";
      overlays = [ outputs.overlays.default ];
      config = {
        allowUnfree = true;
      };
    };

    system.stateVersion = 4;
  };
}
