{ self, lib, config, outputs, globals, ... }:
let
  macUser = globals.user.work;
in
{
  imports = [
  ];

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

    home-manager.users."${macUser}".imports = [
      "${self}/modules/home/darwin"
    ];

    system.stateVersion = 4;
  };
}
