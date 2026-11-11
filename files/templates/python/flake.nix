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

    pyproject-build-systems = {
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
      };
      url = "github:pyproject-nix/build-system-pkgs";
    };

    pyproject-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:pyproject-nix/pyproject.nix";
    };

    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };

    uv2nix = {
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
      };
      url = "github:pyproject-nix/uv2nix";
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
          ...
        }:
        let
          inherit ((lib.importTOML ./pyproject.toml).project) name;
          workspace = inputs.uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };
          pythonSet =
            (pkgs.callPackage inputs.pyproject-nix.build.packages { python = pkgs.python3; }).overrideScope
              (
                lib.composeManyExtensions [
                  inputs.pyproject-build-systems.overlays.default
                  (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
                ]
              );
          editableSet = pythonSet.overrideScope (
            workspace.mkEditablePyprojectOverlay { root = "$REPO_ROOT"; }
          );
        in
        {
          devShells.default = pkgs.mkShell {
            env = {
              UV_NO_SYNC = "1";
              UV_PYTHON_DOWNLOADS = "never";
            };
            inputsFrom = [ config.treefmt.build.devShell ];
            packages = [
              (editableSet.mkVirtualEnv "${name}-dev-env" workspace.deps.all)
              pkgs.basedpyright
              pkgs.uv
            ];
            shellHook = ''
              unset PYTHONPATH
              export REPO_ROOT=$(git rev-parse --show-toplevel)
              ${config.pre-commit.installationScript}
            '';
          };
          packages.default = lib.addMetaAttrs { mainProgram = name; } (
            pythonSet.mkVirtualEnv "${name}-env" workspace.deps.default
          );
          pre-commit.settings.hooks = {
            deadnix.enable = true;
            statix.enable = true;
            treefmt.enable = true;
          };
          treefmt.programs = {
            pedantix.enable = true;
            ruff-check.enable = true;
            ruff-format.enable = true;
          };
        };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
}
