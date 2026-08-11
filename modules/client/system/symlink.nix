{
  flake.modules.homeManager.symlink = { root, ... }: {
    config = {
      swarselsystems.enabledHomeModules = [ "symlink" ];
      home.file = {
        # on NixOS, Emacs does not find the aspell dicts easily. Write the configuration manually
        ".aspell.conf" = {
          source = root "files/config/.aspell.conf";
          target = ".aspell.conf";
        };
        ".gitmessage" = {
          source = root "files/git/.gitmessage";
          target = ".gitmessage";
        };
      };
      xdg.configFile = {
        "tridactyl/themes/swarsel.css".source = root "files/firefox/tridactyl/themes/swarsel.css";
        "tridactyl/tridactylrc".source = root "files/firefox/tridactyl/tridactylrc";
      };
    };
  };
}
