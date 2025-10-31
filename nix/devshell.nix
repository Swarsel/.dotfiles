{ self, inputs, ... }:
{
  imports = [
    inputs.devshell.flakeModule
    inputs.pre-commit-hooks.flakeModule
  ];

  perSystem = { pkgs, system, ... }:
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
            nixpkgs-fmt.enable = true;
            statix.enable = true;
            trim-trailing-whitespace.enable = true;

            destroyed-symlinks = {
              enable = true;
              entry = "${inputs.pre-commit-hooks.checks.${system}.pre-commit-hooks}/bin/destroyed-symlinks";
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

      devshells.default =
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
            pkgs.home-manager
            pkgs.nixpkgs-fmt
            self.packages.${system}.swarsel-build
            self.packages.${system}.swarsel-deploy
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
              command = "nixpkgs-fmt --check \"$FLAKE\"";
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

          devshell.startup.pre-commit-install.text = "pre-commit install";

          env =
            let
              nix-plugins = pkgs.nix-plugins.override {
                nixComponents = pkgs.nixVersions."nixComponents_${nix-version}";
              };
            in
            [
              {
                # Additionally configure nix-plugins with our extra builtins file.
                # We need this for our repo secrets.
                name = "NIX_CONFIG";
                value = ''
                  plugin-files = ${nix-plugins}/lib/nix/plugins
                  extra-builtins-file = ${self + /nix/extra-builtins.nix}
                '';
              }
            ];
        };
    };
}
