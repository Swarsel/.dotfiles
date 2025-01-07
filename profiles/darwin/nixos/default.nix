_:
{

  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs = {
    hostPlatform = "x86_64-darwin";
    overlays = [ outputs.overlays.default ];
    config = {
      allowUnfree = true;
    };
  };

  system.stateVersion = 4;
}
