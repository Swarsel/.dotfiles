{ inputs, lib, config, pkgs, ... }:
let
  moduleName = "spicetify";
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "${moduleName} settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    programs.spicetify = {
      enable = true;
      spotifyPackage = pkgs.stable24_11.spotify;
      enabledExtensions = with spicePkgs.extensions; [
        fullAppDisplay
        shuffle
        hidePodcasts
        fullAlbumDate
        skipStats
        history
      ];
    };
  };
}
