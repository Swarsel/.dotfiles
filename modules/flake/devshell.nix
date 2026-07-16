{
  self,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.devshell = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:numtide/devshell";
  };
}
// lib.optionalAttrs (inputs ? devshell) {
  imports = [
    inputs.devshell.flakeModule
  ];

  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    {
      devshells = {
        default =
          let
            nix-version = "2_30";
          in
          {
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
                command = "home-manager \"$@\"";
                help = "Manage home-manager config";
                name = "hm";
              }
              {
                command = "treefmt --tree-root \"$FLAKE\" \"$@\"";
                help = "Format flake";
                name = "fmt";
              }
              {
                command = "swarsel-deploy \"$@\"";
                help = "Build and deploy this nix config to nodes";
                name = "sd";
              }
              {
                command = "swarsel-deploy \${1} switch";
                help = "Build and deploy a config to nodes";
                name = "sl";
              }
              {
                command = "swarsel-deploy $(hostname) switch";
                help = "Build and switch to the host's config locally";
                name = "sw";
              }
              {
                command = "swarsel-build \"$@\"";
                help = "Build a number of configurations";
                name = "bld";
              }
              {
                command = "git --git-dir=$FLAKE/.git --work-tree=$FLAKE/ \"$@\"";
                help = "Work with the flake git repository";
                name = "c";
              }
            ];
            devshell.startup.pre-commit.text = config.pre-commit.installationScript;
            env =
              let
                nix-plugins = pkgs.stable26_05.nix-plugins.override {
                  nixComponents = pkgs.stable26_05.nixVersions."nixComponents_${nix-version}";
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
            packages = [
              (builtins.trace "alarm: pinned nix_${nix-version}"
                pkgs.stable26_05.nixVersions."nix_${nix-version}"
              )
              pkgs.git
              pkgs.just
              pkgs.age
              pkgs.ssh-to-age
              pkgs.sops
              config.treefmt.build.wrapper
              self.packages.${system}.swarsel-build
              self.packages.${system}.swarsel-deploy
              (pkgs.symlinkJoin {
                buildInputs = [ pkgs.makeWrapper ];
                name = "home-manager";
                paths = [ pkgs.home-manager ];
                postBuild = ''
                  wrapProgram $out/bin/home-manager \
                  --append-flags '--flake .#$(hostname)'
                '';
              })
            ];
          };
        deploy =
          let
            nix-version = "2_28";
          in
          {
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
          };
        hooks.devshell.startup.pre-commit.text = config.pre-commit.installationScript;
      };
    };
}
