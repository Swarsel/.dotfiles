{ lib, config, pkgs, ... }:
{
  options.swarselsystems.server.packages = lib.mkEnableOption "enable packages on server";
  config = lib.mkIf config.swarselsystems.server.packages {
    environment.systemPackages = with pkgs; [
      gnupg
      nix-index
      ssh-to-age
      git
      emacs
      vim
    ];
  };
}
