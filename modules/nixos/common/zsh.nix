{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.zsh = lib.mkEnableOption "zsh base config";
  config = lib.mkIf config.swarselsystems.modules.zsh {
    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;
    environment.shells = with pkgs; [ zsh ];
    environment.pathsToLink = [ "/share/zsh" ];
  };
}
