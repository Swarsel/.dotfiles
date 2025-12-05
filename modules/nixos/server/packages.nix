{ lib, config, pkgs, ... }:
{
  options.swarselmodules.server.packages = lib.mkEnableOption "enable packages on server";
  config = lib.mkIf config.swarselmodules.server.packages {
    environment.systemPackages = with pkgs; [
      gnupg
      nvd
      nix-output-monitor
      ssh-to-age
      git
      emacs
      vim
      sops
      swarsel-deploy
      tmux
      busybox
    ];
  };
}
