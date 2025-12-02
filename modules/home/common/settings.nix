{ self, outputs, lib, pkgs, config, globals, confLib, ... }:
let
  inherit (config.swarselsystems) mainUser flakePath isNixos isLinux;
  inherit (confLib.getConfig.repo.secrets.common) atticPublicKey;
in
{
  options.swarselmodules.general = lib.mkEnableOption "general nix settings";
  config =
    let
      nix-version = "2_30";
    in
    lib.mkIf config.swarselmodules.general {
      nix = lib.mkIf (!config.swarselsystems.isNixos) {
        package = lib.mkForce pkgs.nixVersions."nix_${nix-version}";
        # extraOptions = ''
        #   plugin-files = ${pkgs.dev.nix-plugins}/lib/nix/plugins
        #   extra-builtins-file = ${self + /nix/extra-builtins.nix}
        # '';
        extraOptions =
          let
            nix-plugins = pkgs.nix-plugins.override {
              nixComponents = pkgs.nixVersions."nixComponents_${nix-version}";
            };
          in
          ''
            plugin-files = ${nix-plugins}/lib/nix/plugins
            extra-builtins-file = ${self + /nix/extra-builtins.nix}
          '';
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
            "ca-derivations"
            "cgroups"
            "pipe-operators"
          ];
          substituters = [
            "https://${globals.services.attic.domain}/${mainUser}"
          ];
          trusted-public-keys = [
            atticPublicKey
          ];
          trusted-users = [
            "@wheel"
            "${mainUser}"
            (lib.mkIf ((config.swarselmodules ? server) ? ssh-builder) "builder")
          ];
          connect-timeout = 5;
          bash-prompt-prefix = lib.mkIf config.swarselsystems.isClient "[33m$SHLVL:\\w [0m";
          bash-prompt = lib.mkIf config.swarselsystems.isClient "$(if [[ $? -gt 0 ]]; then printf \"[31m\"; else printf \"[32m\"; fi)λ [0m";
          fallback = true;
          min-free = 128000000;
          max-free = 1000000000;
          auto-optimise-store = true;
          warn-dirty = false;
          max-jobs = 1;
          use-cgroups = lib.mkIf isLinux true;
        };
      };

      nixpkgs = lib.mkIf (!isNixos) {
        overlays = [
          outputs.overlays.default
          (final: prev:
            let
              additions = final: _: import "${self}/pkgs/config" {
                inherit self config lib;
                pkgs = final;
                homeConfig = config;
              };
            in
            additions final prev
          )
        ];
        config = {
          allowUnfree = true;
        };
      };

      programs = {
        # home-manager.enable = lib.mkIf (!isNixos) true;
        man = {
          enable = true;
          generateCaches = true;
        };
      };

      targets.genericLinux.enable = lib.mkIf (!isNixos) true;

      home = {
        username = lib.mkDefault mainUser;
        homeDirectory = lib.mkDefault "/home/${mainUser}";
        stateVersion = lib.mkDefault "23.05";
        keyboard.layout = "us";
        sessionVariables = {
          FLAKE = "/home/${mainUser}/.dotfiles";
        };
        extraOutputsToInstall = [
          "doc"
          "info"
          "devdoc"
        ];
        packages = lib.mkIf (!isNixos) [
          (pkgs.symlinkJoin {
            name = "home-manager";
            buildInputs = [ pkgs.makeWrapper ];
            paths = [ pkgs.home-manager ];
            postBuild = ''
                  wrapProgram $out/bin/home-manager \
              --append-flags '--flake ${flakePath}#$(hostname)'
            '';
          })
        ];
      };
    };

}
