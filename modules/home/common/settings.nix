{ self, lib, pkgs, config, ... }:
let
  inherit (config.swarselsystems) mainUser;
in
{
  options.swarselmodules.general = lib.mkEnableOption "general nix settings";
  config = lib.mkIf config.swarselmodules.general {
    nix = lib.mkIf (!config.swarselsystems.isNixos) {
      package = lib.mkForce pkgs.nixVersions.nix_2_28;
      extraOptions = ''
        plugin-files = ${pkgs.nix-plugins.overrideAttrs (o: {
          buildInputs = [pkgs.nixVersions.nix_2_28 pkgs.boost];
          patches = (o.patches or []) ++ ["${self}/nix/nix-plugins.patch"];
        })}/lib/nix/plugins
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
        trusted-users = [ "@wheel" "${mainUser}" ];
        connect-timeout = 5;
        bash-prompt-prefix = "[33m$SHLVL:\\w [0m";
        bash-prompt = "$(if [[ $? -gt 0 ]]; then printf \"[31m\"; else printf \"[32m\"; fi)λ [0m";
        fallback = true;
        min-free = 128000000;
        max-free = 1000000000;
        auto-optimise-store = true;
        warn-dirty = false;
        max-jobs = 1;
        use-cgroups = lib.mkIf config.swarselsystems.isLinux true;
      };
    };

    nixpkgs.overlays = lib.mkIf config.swarselsystems.isNixos (lib.mkForce null);

    programs.home-manager.enable = lib.mkIf (!config.swarselsystems.isNixos) true;
    targets.genericLinux.enable = lib.mkIf (!config.swarselsystems.isNixos) true;

    home = {
      username = lib.mkDefault mainUser;
      homeDirectory = lib.mkDefault "/home/${mainUser}";
      stateVersion = lib.mkDefault "23.05";
      keyboard.layout = "us";
      sessionVariables = {
        FLAKE = "/home/${mainUser}/.dotfiles";
      };
    };
  };

}
