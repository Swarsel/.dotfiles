# heavily inspired by https://github.com/nulladmin1/nix-flake-templates/blob/main/go-nix/flake.nix
{
  description = "Go Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    { self
    , nixpkgs
    , systems
    , ...
    }:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
      pkgsFor = forEachSystem (system: import nixpkgs { inherit system; });

      pname = "name";
    in
    {
      formatter = forEachSystem (system: pkgsFor.${system}.nixpkgs-fmt);

      devShells = forEachSystem (system: {
        default = pkgsFor.${system}.mkShell {
          packages = with pkgsFor.${system}; [
            go
            gopls
            go-tools
            gotools
          ];
        };
      });

      packages = forEachSystem (system: {
        default = pkgsFor.${system}.buildGoModule {
          inherit pname;
          version = "0.1.0";
          src = ./.;
          vendorHash = null;
        };
      });

      apps = forEachSystem (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/${pname}";
        };
      });
    };
}
