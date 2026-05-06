{ inputs, pkgs, ... }:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
in
{
  config = {
    swarselsystems.enabledHomeModules = [ "spicetify" ];
    programs.spicetify = {
      enable = true;
      # spotifyPackage = pkgs.stable24_11.spotify;
      spotifyPackage = pkgs.spotify;
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
