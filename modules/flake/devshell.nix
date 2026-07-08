{
  self,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs = {
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
// lib.optionalAttrs (inputs ? devshell && inputs ? pre-commit-hooks) {
  imports = [
    inputs.devshell.flakeModule
    inputs.pre-commit-hooks.flakeModule
  ];

  perSystem =
    {
      pkgs,
      config,
      system,
      ...
    }:
    {
      pre-commit = {
        check.enable = true;
        settings = {
          addGcRoot = true;
          hooks = {
            check-added-large-files.enable = true;
            check-case-conflicts.enable = true;
            check-executables-have-shebangs.enable = true;
            check-shebang-scripts-are-executable.enable = false;
            check-merge-conflicts.enable = true;
            deadnix.enable = true;
            detect-private-keys.enable = true;
            end-of-file-fixer.enable = true;
            fix-byte-order-marker.enable = true;
            flake-checker.enable = true;
            forbid-new-submodules.enable = true;
            mixed-line-endings.enable = true;
            nixfmt-rfc-style.enable = true;
            statix.enable = true;
            trim-trailing-whitespace.enable = true;
            treefmt.enable = true;

            destroyed-symlinks = {
              enable = true;
              entry = "${inputs.pre-commit-hooks.checks.${system}.pre-commit-hooks}/bin/destroyed-symlinks";
            };

            org-custom-ids = {
              enable = true;
              name = "org-custom-ids";
              description = "Generate a :CUSTOM_ID: for every org heading that is missing one";
              entry = lib.getExe self.packages.${system}.check-org-custom-ids;
              files = "^SwarselSystems\\.org$";
              pass_filenames = true;
            };

            topology-in-sync = {
              enable = true;
              name = "topology-in-sync";
              description = "Ensure topology.png and topology_small.png are committed together";
              entry = lib.getExe self.packages.${system}.check-topology-in-sync;
              files = "^files/topology/topology(_small)?\\.png$";
              pass_filenames = false;
            };

            org-in-sync = {
              enable = true;
              name = "org-in-sync";
              description = "Ensure SwarselSystems.org is in sync with its tangled files";
              entry = lib.getExe self.packages.${system}.check-org-in-sync;
              always_run = true;
              pass_filenames = false;
            };

            modules-tangled = {
              enable = true;
              name = "modules-tangled";
              description = "Ensure every file under modules/ is tangled from SwarselSystems.org";
              entry = lib.getExe self.packages.${system}.check-modules-tangled;
              always_run = true;
              pass_filenames = false;
            };

            shellcheck = {
              enable = true;
              entry = "${pkgs.shellcheck}/bin/shellcheck --shell=bash";
            };

            shfmt = {
              enable = true;
              entry = "${pkgs.shfmt}/bin/shfmt -i 4 -sr -d -s -l";
            };
          };
        };
      };

      devshells = {
        deploy =
          let
            nix-version = "2_28";
          in
          {
            packages = [
              (builtins.trace "alarm: pinned nix_${nix-version}"
                pkgs.stable25_05.nixVersions."nix_${nix-version}"
              )
              pkgs.git
              pkgs.just
              pkgs.age
              pkgs.ssh-to-age
              pkgs.sops
              pkgs.opentofu
              self.packages.${system}.swarsel-bootstrap
            ];

            env = [
              {
                name = "NIX_CONFIG";
                value = ''
                  plugin-files = ${
                    pkgs.stable25_05.nix-plugins.overrideAttrs (o: {
                      buildInputs = [
                        pkgs.stable25_05.nixVersions."nix_${nix-version}"
                        pkgs.stable25_05.boost
                      ];
                      patches = (o.patches or [ ]) ++ [ (self + /files/patches/nix-plugins.patch) ];
                    })
                  }/lib/nix/plugins
                  extra-builtins-file = ${self + /files/nix/extra-builtins.nix}
                '';
              }
            ];
          };

        hooks.devshell.startup.pre-commit.text = config.pre-commit.installationScript;
        default =
          let
            nix-version = "2_30";
          in
          {
            packages = [
              (builtins.trace "alarm: pinned nix_${nix-version}" pkgs.nixVersions."nix_${nix-version}")
              pkgs.git
              pkgs.just
              pkgs.age
              pkgs.ssh-to-age
              pkgs.sops
              pkgs.nixfmt
              self.packages.${system}.swarsel-build
              self.packages.${system}.swarsel-deploy
              (pkgs.symlinkJoin {
                name = "home-manager";
                buildInputs = [ pkgs.makeWrapper ];
                paths = [ pkgs.home-manager ];
                postBuild = ''
                  wrapProgram $out/bin/home-manager \
                  --append-flags '--flake .#$(hostname)'
                '';
              })
            ];

            commands = [
              {
                package = pkgs.statix;
                help = "Lint flake";
              }
              {
                package = pkgs.deadnix;
                help = "Check flake for dead code";
              }
              {
                package = pkgs.nix-tree;
                help = "Interactively browse dependency graphs of Nix derivations";
              }
              {
                package = pkgs.nvd;
                help = "Diff two nix toplevels and show which packages were upgraded";
              }
              {
                package = pkgs.nix-diff;
                help = "Explain why two Nix derivations differ";
              }
              {
                package = pkgs.nix-output-monitor;
                help = "Nix Output Monitor (a drop-in alternative for `nix` which shows a build graph)";
                name = "nom \"$@\"";
              }
              {
                name = "hm";
                help = "Manage home-manager config";
                command = "home-manager \"$@\"";
              }
              {
                name = "fmt";
                help = "Format flake";
                command = "find \"$FLAKE\" -name '*.nix' -exec nixfmt --check {} +";
              }
              {
                name = "sd";
                help = "Build and deploy this nix config to nodes";
                command = "swarsel-deploy \"$@\"";
              }
              {
                name = "sl";
                help = "Build and deploy a config to nodes";
                command = "swarsel-deploy \${1} switch";
              }
              {
                name = "sw";
                help = "Build and switch to the host's config locally";
                command = "swarsel-deploy $(hostname) switch";
              }
              {
                name = "bld";
                help = "Build a number of configurations";
                command = "swarsel-build \"$@\"";
              }
              {
                name = "c";
                help = "Work with the flake git repository";
                command = "git --git-dir=$FLAKE/.git --work-tree=$FLAKE/ \"$@\"";
              }
            ];

            devshell.startup.pre-commit.text = config.pre-commit.installationScript;

            env =
              let
                nix-plugins = pkgs.nix-plugins.override {
                  nixComponents = pkgs.nixVersions."nixComponents_${nix-version}";
                };
              in
              [
                {
                  name = "NIX_CONFIG";
                  value = ''
                    plugin-files = ${nix-plugins}/lib/nix/plugins
                    extra-builtins-file = ${self + /files/nix/extra-builtins.nix}
                  '';
                }
              ];
          };
      };
    };
}
