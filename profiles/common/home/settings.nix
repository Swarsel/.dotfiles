{ self, lib, config, pkgs, ... }:
{
  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
        "pipe-operators"
      ];
    };
  };

  programs.home-manager.enable = lib.mkIf (!config.swarselsystems.isNixos) true;

  home = {
    username = lib.mkDefault "swarsel";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "23.05";
    keyboard.layout = "us";
    sessionVariables = {
      FLAKE = "${self}";
    };
  };
}
