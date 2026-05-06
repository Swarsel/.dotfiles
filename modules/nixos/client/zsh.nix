{ pkgs, ... }:
{
  config = {
    programs.zsh = {
      enable = true;
      enableCompletion = false;
    };
    users.defaultUserShell = pkgs.zsh;
    environment.shells = with pkgs; [ zsh ];
    environment.pathsToLink = [ "/share/zsh" ];
  };
}
