{ self, lib, config, ... }:
{
  options.swarselsystems.modules.symlink = lib.mkEnableOption "symlink settings";
  config = lib.mkIf config.swarselsystems.modules.symlink {
    home.file = {
      "init.el" = lib.mkDefault {
        source = self + /programs/emacs/init.el;
        target = ".emacs.d/init.el";
      };
      "early-init.el" = {
        source = self + /programs/emacs/early-init.el;
        target = ".emacs.d/early-init.el";
      };
      # on NixOS, Emacs does not find the aspell dicts easily. Write the configuration manually
      ".aspell.conf" = {
        source = self + /programs/config/.aspell.conf;
        target = ".aspell.conf";
      };
      ".gitmessage" = {
        source = self + /programs/git/.gitmessage;
        target = ".gitmessage";
      };
    };

    xdg.configFile = {
      "tridactyl/tridactylrc".source = self + /programs/firefox/tridactyl/tridactylrc;
      "tridactyl/themes/base16-codeschool.css".source = self + /programs/firefox/tridactyl/themes/base16-codeschool.css;
      "tridactyl/themes/swarsel.css".source = self + /programs/firefox/tridactyl/themes/swarsel.css;
      "swayidle/config".source = self + /programs/swayidle/config;
    };
  };
}
