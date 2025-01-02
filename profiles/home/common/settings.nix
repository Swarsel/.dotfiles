{ lib, config, ... }:
{
  nix = lib.mkIf (!config.swarselsystems.isNixos) {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
        "cgroups"
        "pipe-operators"
      ];
      trusted-users = [ "@wheel" "swarsel" ];
      connect-timeout = 5;
      bash-prompt-prefix = "[33m$SHLVL:\\w [0m";
      bash-prompt = "$(if [[ $? -gt 0 ]]; then printf \"[31m\"; else printf \"[32m\"; fi)\[\e[1m\]λ\[\e[0m\] [0m";
      fallback = true;
      min-free = 128000000;
      max-free = 1000000000;
      auto-optimise-store = true;
      warn-dirty = false;
      max-jobs = 1;
      use-cgroups = lib.mkIf config.swarselsystems.isLinux true;
    };
  };

  programs.home-manager.enable = lib.mkIf (!config.swarselsystems.isNixos) true;

  home = {
    username = lib.mkDefault "swarsel";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "23.05";
    keyboard.layout = "us";
    sessionVariables = {
      FLAKE = "${config.home.homeDirectory}/.dotfiles";
    };
  };

}
