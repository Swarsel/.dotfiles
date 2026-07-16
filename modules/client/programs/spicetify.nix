{
  flake-file.inputs.spicetify-nix = {
    inputs = {
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
    };
    url = "github:Gerg-l/spicetify-nix";
  };

  flake.modules.homeManager.spicetify =
    {
      inputs,
      lib,
      arch,
      ...
    }:
    {
      imports = lib.optionals (inputs ? spicetify-nix && arch == "x86_64-linux") [
        inputs.spicetify-nix.homeManagerModules.default
        (
          { inputs, pkgs, ... }:
          let
            spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
          in
          {
            swarselsystems.enabledHomeModules = [ "spicetify" ];
            programs.spicetify = {
              enable = true;
              enabledExtensions = with spicePkgs.extensions; [
                fullAppDisplay
                shuffle
                hidePodcasts
                fullAlbumDate
                skipStats
                history
              ];
              # spotifyPackage = pkgs.stable24_11.spotify;
              spotifyPackage = pkgs.spotify;
            };
          }
        )
      ];
    };
}
