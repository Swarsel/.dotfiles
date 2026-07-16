{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init = {
    prelude = ''
      (setq treesit-enabled-modes t)
    '';

    usePackage = {
      treesit-fold = {
        config = "(global-treesit-fold-mode 1)";
        enable = true;
      };
      treesit-grammars = {
        enable = true;
        package = epkgs: epkgs.treesit-grammars.with-all-grammars;
        enableUsePackage = false;
      };
    };
  };
}
