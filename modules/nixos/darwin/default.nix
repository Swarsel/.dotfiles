{ self, lib, config, outputs, globals, ... }:
let
  macUser = globals.user.work;
in
{
  imports = [
  ];

  options.swarselmodules.optional.darwin = lib.mkEnableOption "optional darwin settings";
  config = lib.mkIf config.swarselmodules.optional.darwin {
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
