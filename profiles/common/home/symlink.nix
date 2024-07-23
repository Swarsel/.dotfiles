{ ... }:
{
  home.file = {
    "init.el" = {
      source = ../../../programs/emacs/init.el;
      target = ".emacs.d/init.el";
    };
    "early-init.el" = {
      source = ../../../programs/emacs/early-init.el;
      target = ".emacs.d/early-init.el";
    };
    # on NixOS, Emacs does not find the aspell dicts easily. Write the configuration manually
    ".aspell.conf" = {
      source = ../../../programs/config/.aspell.conf;
      target = ".aspell.conf";
    };
    ".gitmessage" = {
      source = ../../../programs/git/.gitmessage;
      target = ".gitmessage";
    };
  };

  xdg.configFile = {
    "tridactyl/tridactylrc".source = ../../../programs/firefox/tridactyl/tridactylrc;
    "tridactyl/themes/base16-codeschool.css".source = ../../../programs/firefox/tridactyl/themes/base16-codeschool.css;
  };
}
