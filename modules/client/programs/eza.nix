{
  flake.modules.homeManager.eza = {
    config = {
      swarselsystems.enabledHomeModules = [ "eza" ];
      programs.eza = {
        enable = true;
        icons = "auto";
        git = true;
        extraOptions = [
          "-l"
          "--group-directories-first"
        ];
      };
    };
  };
}
