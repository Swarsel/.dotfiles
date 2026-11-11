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
              delve
              gopls
            ];
            shellHook = config.pre-commit.installationScript;
          };
          packages.default =
            let
              name = baseNameOf (lib.head (builtins.match "module ([^\n]+)\n.*" (builtins.readFile ./go.mod)));
            in
            pkgs.buildGoModule {
              pname = name;
              src = lib.fileset.toSource {
                fileset = lib.fileset.unions [
                  ./go.mod
                  (lib.fileset.fileFilter (file: file.hasExt "go") ./.)
                ];
                root = ./.;
              };
              vendorHash = null;
              version = "0.1.0";
              meta.mainProgram = name;
            };
          pre-commit.settings.hooks = {
            deadnix.enable = true;
            statix.enable = true;
            treefmt.enable = true;
          };
          treefmt.programs = {
            gofmt.enable = true;
            pedantix.enable = true;
          };
        };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
}
