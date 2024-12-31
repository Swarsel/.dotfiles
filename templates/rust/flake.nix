{
  description = "Nix Flake Template for Rust using Fenix and Naersk";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
    naersk.url = "github:nix-community/naersk";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , naersk
    , fenix
    , systems
    , ...
    }:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
      pkgsFor = forEachSystem (system:

        import nixpkgs {
          inherit system;
          overlays = [
            fenix.overlays.default
          ];
        });
      rust-toolchain = forEachSystem (system: pkgsFor.${system}.fenix.stable);
    in
    {
      formatter = forEachSystem (system: pkgsFor.${system}.nixpkgs-fmt);

      devShells = forEachSystem (system: {
        default = pkgsFor.${system}.mkShell {
          packages = with rust-toolchain.${system}; [
            cargo
            rustc
            clippy
            rustfmt
            rust-analyzer
          ];
          env = {
            RUST_BACKTRACE = "full";
          };
          RUST_SRC_PATH = "${rust-toolchain.${system}.rust-src}/lib/rustlib/src/rust/library";
        };
      });

      packages = forEachSystem (system: {
        default =
          (pkgsFor.${system}.callPackage naersk {
            inherit (rust-toolchain.${system}) cargo rustc;
          }).buildPackage {
            src = ./.;
          };
      });

      apps = forEachSystem (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/rust";
        };
      });
    };
}
