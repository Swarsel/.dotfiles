{
  flake.modules.homeManager.symlink = { self, ... }: {
    config = {
      swarselsystems.enabledHomeModules = [ "symlink" ];
      home.file = {
        # on NixOS, Emacs does not find the aspell dicts easily. Write the configuration manually
        ".aspell.conf" = {
          source = self + /files/config/.aspell.conf;
          target = ".aspell.conf";
        };
        ".gitmessage" = {
          source = self + /files/git/.gitmessage;
          target = ".gitmessage";
        };
      };
      xdg.configFile = {
        "tridactyl/themes/base16-codeschool.css".source =
          self + /files/firefox/tridactyl/themes/base16-codeschool.css;
        "tridactyl/themes/swarsel.css".source = self + /files/firefox/tridactyl/themes/swarsel.css;
        "tridactyl/tridactylrc".source = self + /files/firefox/tridactyl/tridactylrc;
      };
    };
  };
}
