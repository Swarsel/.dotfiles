{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.server.packages = lib.mkEnableOption "enable packages on server";
  config = lib.mkIf config.swarselsystems.modules.server.packages {
    environment.systemPackages = with pkgs; [
      gnupg
      nix-index
      nvd
      nix-output-monitor
      ssh-to-age
      git
      emacs
      vim
      sops
      swarsel-deploy
    ];
  };
}
