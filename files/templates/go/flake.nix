# heavily inspired by https://github.com/nulladmin1/nix-flake-templates/blob/main/go-nix/flake.nix
{
  description = "Go Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      ...
    }:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
      pkgsFor = forEachSystem (system: import nixpkgs { inherit system; });

      pname = "name";
    in
    {
      apps = forEachSystem (system: {
        default = {
          program = "${self.packages.${system}.default}/bin/${pname}";
          type = "app";
        };
      });

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

      formatter = forEachSystem (system: pkgsFor.${system}.nixfmt);

      packages = forEachSystem (system: {
        default = pkgsFor.${system}.buildGoModule {
          inherit pname;
          src = ./.;
          vendorHash = null;
          version = "0.1.0";
        };
      });
    };
}
