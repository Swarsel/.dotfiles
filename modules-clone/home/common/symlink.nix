{ self, lib, config, ... }:
{
  options.swarselmodules.symlink = lib.mkEnableOption "symlink settings";
  config = lib.mkIf config.swarselmodules.symlink {
    home.file = {
      "init.el" = lib.mkDefault {
        source = self + /files/emacs/init.el;
        target = ".emacs.d/init.el";
      };
      "early-init.el" = {
        source = self + /files/emacs/early-init.el;
        target = ".emacs.d/early-init.el";
      };
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
      "tridactyl/tridactylrc".source = self + /files/firefox/tridactyl/tridactylrc;
      "tridactyl/themes/base16-codeschool.css".source = self + /files/firefox/tridactyl/themes/base16-codeschool.css;
      "tridactyl/themes/swarsel.css".source = self + /files/firefox/tridactyl/themes/swarsel.css;
      # "swayidle/config".source = self + /files/swayidle/config;
    };
  };
}
