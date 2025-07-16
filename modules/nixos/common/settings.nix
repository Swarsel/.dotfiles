{ self, lib, pkgs, config, outputs, inputs, minimal, ... }:
let
  settings = if minimal then { } else {
    environment.etc."nixos/configuration.nix".source = pkgs.writeText "configuration.nix" ''
      assert builtins.trace "This location is not used. The config is found in ${config.swarselsystems.flakePath}!" false;
      { }
    '';

    nix =
      let
        flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
      in
      {
        settings = {
          connect-timeout = 5;
          bash-prompt-prefix = "[33m$SHLVL:\\w [0m";
          bash-prompt = "$(if [[ $? -gt 0 ]]; then printf \"[31m\"; else printf \"[32m\"; fi)λ [0m";
          fallback = true;
          min-free = 128000000;
          max-free = 1000000000;
          flake-registry = "";
          auto-optimise-store = true;
          warn-dirty = false;
          max-jobs = 1;
          use-cgroups = lib.mkIf config.swarselsystems.isLinux true;
        };
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 10d";
        };
        optimise = {
          automatic = true;
          dates = "weekly";
        };
        channel.enable = false;
        registry = rec {
          nixpkgs.flake = inputs.nixpkgs;
          swarsel.flake = inputs.swarsel;
          n = nixpkgs;
          s = swarsel;
        };
        nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
      };

    services.dbus.implementation = "broker";

    systemd.services.nix-daemon = {
      environment.TMPDIR = "/var/tmp";
    };

  };
in
{
  options.swarselsystems.modules.general = lib.mkEnableOption "general nix settings";
  config = lib.mkIf config.swarselsystems.modules.general
    (lib.recursiveUpdate
      {
        sops.secrets.github-api-token = lib.mkIf (!minimal) {
          sopsFile = "${config.swarselsystems.flakePath}/secrets/general/secrets.yaml";
        };

        nix = {
          package = pkgs.nixVersions.nix_2_28;
          settings = {
            experimental-features = [
              "nix-command"
              "flakes"
              "ca-derivations"
              "cgroups"
              "pipe-operators"
            ];
            trusted-users = [ "@wheel" "${config.swarselsystems.mainUser}" ];
          };
          # extraOptions = ''
          #   plugin-files = ${pkgs.nix-plugins}/lib/nix/plugins
          #   extra-builtins-file = ${self + /nix/extra-builtins.nix}
          # '';
          extraOptions = ''
            plugin-files = ${pkgs.nix-plugins.overrideAttrs (o: {
              buildInputs = [pkgs.nixVersions.nix_2_28 pkgs.boost];
              patches = (o.patches or []) ++ ["${self}/nix/nix-plugins.patch"];
            })}/lib/nix/plugins
            extra-builtins-file = ${self + /nix/extra-builtins.nix}
          '' + lib.optionalString (!minimal) ''
            !include ${config.sops.secrets.github-api-token.path}
          '';
        };

        system.stateVersion = lib.mkDefault "23.05";

        nixpkgs = {
          overlays = [ outputs.overlays.default ];
          config = {
            allowUnfree = true;
          };
        };

      }
      settings);
}
