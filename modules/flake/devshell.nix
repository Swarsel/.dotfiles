{
  self,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.devshell = {
    url = "github:numtide/devshell";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
// lib.optionalAttrs (inputs ? devshell) {
  imports = [
    inputs.devshell.flakeModule
  ];

  perSystem =
    {
      pkgs,
      config,
      system,
      ...
    }:
    {
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
