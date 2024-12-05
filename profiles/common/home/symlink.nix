{ self, ... }:
{
  home.file = {
    "init.el" = {
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
    "swayidle/config" = {
      source = self + /programs/swayidle/config;
      target = ".config/swayidle/config";
    };
  };

xdg.configFile = {
    "tridactyl/tridactylrc".source = self + /programs/firefox/tridactyl/tridactylrc;
    "tridactyl/themes/base16-codeschool.css".source = self + /programs/firefox/tridactyl/themes/base16-codeschool.css;
  };
}
