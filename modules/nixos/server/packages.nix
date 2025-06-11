{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.server.packages = lib.mkEnableOption "enable packages on server";
  config = lib.mkIf config.swarselsystems.modules.server.packages {
    environment.systemPackages = with pkgs; [
      gnupg
      nix-index
      nvd
      ssh-to-age
      git
      emacs
      vim
    ];
  };
}
