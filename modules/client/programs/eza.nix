{
  flake.modules.homeManager.eza.config = {
    swarselsystems.enabledHomeModules = [ "eza" ];
    programs.eza = {
      enable = true;
      extraOptions = [
        "-l"
        "--group-directories-first"
      ];
      git = true;
      icons = "auto";
    };
  };
}
