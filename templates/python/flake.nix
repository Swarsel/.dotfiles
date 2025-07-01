# based on https://github.com/pyproject-nix/uv2nix/tree/master/templates/hello-world
{
  description = "Python flake using uv2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs = {
        pyproject-nix.follows = "pyproject-nix";
        nixpkgs.follows = "nixpkgs";
      };
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs = {
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs =
    { nixpkgs
    , uv2nix
    , pyproject-nix
    , pyproject-build-systems
    , ...
    }:
    let
      inherit (nixpkgs) lib;
      pname = "name";
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;

      # Load a uv workspace from a workspace root.
      # Uv2nix treats all uv projects as workspace projects.
      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

      overlay = workspace.mkPyprojectOverlay {
        # Prefer prebuilt binary wheels as a package source.
        # Sdists are less likely to "just work" because of the metadata missing from uv.lock.
        # Binary wheels are more likely to, but may still require overrides for library dependencies.
        sourcePreference = "wheel"; # or sourcePreference = "sdist";
        # Optionally customise PEP 508 environment
        # environ = {
        #   platform_release = "5.10.65";
        # };
      };


      pythonSets = forAllSystems
        (system:
          let
            inherit (pkgs) stdenv;
            pkgs = nixpkgs.legacyPackages.${system};
            pyprojectOverrides = final: prev: {
              # Implement build fixups here.
              ${pname} = prev.${pname}.overrideAttrs (old: {

                passthru = old.passthru // {
                  # Put all tests in the passthru.tests attribute set.
                  # Nixpkgs also uses the passthru.tests mechanism for ofborg test discovery.
                  #
                  # For usage with Flakes we will refer to the passthru.tests attributes to construct the flake checks attribute set.
                  tests =
                    let

                      virtualenv = final.mkVirtualEnv "${pname}-pytest-env" {
                        ${pname} = [ "test" ];
                      };

                    in
                    (old.tests or { })
                      // {
                      pytest = stdenv.mkDerivation {
                        name = "${final.${pname}.name}-pytest";
                        inherit (final.${pname}) src;
                        nativeBuildInputs = [
                          virtualenv
                        ];
                        dontConfigure = true;

                        # Because this package is running tests, and not actually building the main package
                        # the build phase is running the tests.
                        #
                        # We also output a HTML coverage report, which is used as the build output.
                        buildPhase = ''
                          runHook preBuild
                          pytest --cov tests --cov-report html
                          runHook postBuild
                        '';

                        # Install the HTML coverage report into the build output.
                        #
                        # If you wanted to install multiple test output formats such as TAP outputs
                        # you could make this derivation a multiple-output derivation.
                        #
                        # See https://nixos.org/manual/nixpkgs/stable/#chap-multiple-output for more information on multiple outputs.
                        installPhase = ''
                          runHook preInstall
                          mv htmlcov $out
                          runHook postInstall
                        '';
                      };

                    };
                };
              });
            };

            baseSet = pkgs.callPackage pyproject-nix.build.packages {
              python = pkgs.python312;
            };
          in
          baseSet.overrideScope
            (
              lib.composeManyExtensions [
                pyproject-build-systems.overlays.default
                overlay
                pyprojectOverrides
              ]
            ));

    in
    {
      packages = forAllSystems (system:
        let
          pythonSet = pythonSets.${system};
        in
        { default = pythonSet.mkVirtualEnv "${pname}-env" workspace.deps.default; });

      devShells = forAllSystems
        (system:
          let
            pythonSet = pythonSets.${system};
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default =
              let
                # Create an overlay enabling editable mode for all local dependencies.
                editableOverlay = workspace.mkEditablePyprojectOverlay {
                  # Use environment variable
                  root = "$REPO_ROOT";
                  # Optional: Only enable editable for these packages
                  # members = [ "hello-world" ];
                };

                # Override previous set with our overrideable overlay.
                editablePythonSet = pythonSet.overrideScope editableOverlay;

                virtualenv = editablePythonSet.mkVirtualEnv "${pname}-dev-env" {
                  ${pname} = [ "dev" ];
                };

              in
              pkgs.mkShell {
                packages = [
                  virtualenv
                  pkgs.uv
                ];
                shellHook = ''
                  # Undo dependency propagation by nixpkgs.
                  unset PYTHONPATH

                  # Don't create venv using uv
                  export UV_NO_SYNC=1

                  # Prevent uv from downloading managed Python's
                  export UV_PYTHON_DOWNLOADS=never

                  # Get repository root using git. This is expanded at runtime by the editable `.pth` machinery.
                  export REPO_ROOT=$(git rev-parse --show-toplevel)
                '';
              };
          });

      checks = forAllSystems (
        system:
        let
          pythonSet = pythonSets.${system};
        in
        {
          inherit (pythonSet.${pname}.passthru.tests) pytest;
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

    };
}
