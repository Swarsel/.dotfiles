{ self, ... }:
let
  profilesPath = "${self}/profiles";
in
{
  imports = [
    "${profilesPath}/common/nixos/home-manager.nix"
  ];

  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs = {
    hostPlatform = "x86_64-darwin";
    overlays = outputs.overlaysList;
    config = {
      allowUnfree = true;
    };
  };

  system.stateVersion = 4;
}
