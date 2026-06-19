{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init = {
    prelude = ''
      (setq treesit-enabled-modes t)
    '';

    usePackage = {
      treesit-grammars = {
        enable = true;
        package = epkgs: epkgs.treesit-grammars.with-all-grammars;
        enableUsePackage = false;
      };

      treesit-fold = {
        enable = true;
        config = "(global-treesit-fold-mode 1)";
      };
    };
  };
}
