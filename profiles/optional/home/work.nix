{ pkgs, ... }:

{
  home.packages = with pkgs; [
    teams-for-linux
    google-chrome
  ];
}
