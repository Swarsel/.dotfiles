# heavily inspired by https://github.com/nulladmin1/nix-flake-templates/blob/main/rust-fenix-naersk/flake.nix
{
  description = "Rust Flake using Fenix and Naersk";

  inputs = {
    fenix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/fenix";
    };

    naersk.url = "github:nix-community/naersk";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      self,
      fenix,
      naersk,
      nixpkgs,
      systems,
      ...
    }:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
      pkgsFor = forEachSystem (
        system:

        import nixpkgs {
          inherit system;
          overlays = [
            fenix.overlays.default
          ];
        }
      );
      rust-toolchain = forEachSystem (system: pkgsFor.${system}.fenix.stable);
    in
    {
      apps = forEachSystem (system: {
        default = {
          program = "${self.packages.${system}.default}/bin/rust";
          type = "app";
        };
      });

      devShells = forEachSystem (system: {
        default = pkgsFor.${system}.mkShell {
          RUST_SRC_PATH = "${rust-toolchain.${system}.rust-src}/lib/rustlib/src/rust/library";
          env.RUST_BACKTRACE = "full";
          packages = with rust-toolchain.${system}; [
            cargo
            rustc
            clippy
            rustfmt
            rust-analyzer
          ];
        };
      });

      formatter = forEachSystem (system: pkgsFor.${system}.nixfmt);

      packages = forEachSystem (system: {
        default =
          (pkgsFor.${system}.callPackage naersk {
            inherit (rust-toolchain.${system}) cargo rustc;
          }).buildPackage
            {
              src = ./.;
            };
      });
    };
}
