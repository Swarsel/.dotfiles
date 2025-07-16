{ lib, config, pkgs, ... }:
{
  options.swarselmodules.zsh = lib.mkEnableOption "zsh base config";
  config = lib.mkIf config.swarselmodules.zsh {
    programs.zsh = {
      enable = true;
      enableCompletion = false;
    };
    users.defaultUserShell = pkgs.zsh;
    environment.shells = with pkgs; [ zsh ];
    environment.pathsToLink = [ "/share/zsh" ];
  };
}
