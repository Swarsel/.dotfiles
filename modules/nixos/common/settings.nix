{ lib, pkgs, config, outputs, inputs, minimal, ... }:
{
  options.swarselsystems.modules.general = lib.mkEnableOption "general nix settings";
  config = lib.mkIf config.swarselsystems.modules.general
    ({

      system.stateVersion = lib.mkDefault "23.05";

      nixpkgs = {
        overlays = [ outputs.overlays.default ];
        config = {
          allowUnfree = true;
        };
      };

    }
    // lib.optionalAttrs (!minimal) {

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
            experimental-features = [
              "nix-command"
              "flakes"
              "ca-derivations"
              "cgroups"
              "pipe-operators"
            ];
            trusted-users = [ "@wheel" "${config.swarselsystems.mainUser}" ];
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
            p = nixpkgs;
          };
          nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
        };

      services.dbus.implementation = "broker";

      systemd.services.nix-daemon = {
        environment.TMPDIR = "/var/tmp";
      };

    });
}
