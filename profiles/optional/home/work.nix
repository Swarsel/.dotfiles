{ pkgs, ... }:

{
  home.packages = with pkgs; [
    teams-for-linux
    google-chrome
  ];

  programs.ssh = {
    matchBlocks = {
      "*.vbc.ac.at" = {
        user = "dc_adm_schwarzaeugl";
      };
    };
  };

}
