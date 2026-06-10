{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    treesit-auto = {
      enable = true;
      custom = {
        treesit-auto-install = true;
      };
      config = ''
        (treesit-auto-add-to-auto-mode-alist 'all)
        (global-treesit-auto-mode)
      '';
    };

    treesit-grammars = {
      enable = true;
      package = epkgs: epkgs.treesit-grammars.with-all-grammars;
      enableUsePackage = false;
    };
  };
}
