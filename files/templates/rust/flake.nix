{
  description = "name";

  inputs = {
    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs";
      url = "github:hercules-ci/flake-parts";
    };

    git-hooks-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/git-hooks.nix";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    pedantix = {
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "git-hooks-nix";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
      url = "github:Swarsel/pedantix";
    };

    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.git-hooks-nix.flakeModule
        inputs.pedantix.flakeModules.default
        inputs.treefmt-nix.flakeModule
      ];
      perSystem =
        {
          config,
          lib,
          pkgs,
          self',
          ...
        }:
        {
          devShells.default = pkgs.mkShell {
            inputsFrom = [
              self'.packages.default
              config.treefmt.build.devShell
            ];
            packages = with pkgs; [
              clippy
              gdb
              rust-analyzer
            ];
            shellHook = config.pre-commit.installationScript;
          };
          packages.default =
            let
              manifest = (lib.importTOML ./Cargo.toml).package;
            in
            pkgs.rustPlatform.buildRustPackage {
              inherit (manifest) version;
              cargoLock.lockFile = ./Cargo.lock;
              pname = manifest.name;
              src = lib.fileset.toSource {
                fileset = lib.fileset.unions [
                  ./Cargo.toml
                  ./Cargo.lock
                  ./src
                ];
                root = ./.;
              };
              meta.mainProgram = manifest.name;
            };
          pre-commit.settings = {
            hooks = {
              clippy.enable = true;
              deadnix.enable = true;
              statix.enable = true;
              treefmt.enable = true;
            };
            settings.rust = {
              cargoManifestPath = "./Cargo.toml";
              check.cargoDeps = pkgs.rustPlatform.importCargoLock { lockFile = ./Cargo.lock; };
            };
          };
          treefmt.programs = {
            pedantix.enable = true;
            rustfmt.enable = true;
            taplo.enable = true;
          };
        };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
}
