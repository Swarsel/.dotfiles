{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init = {
    usePackage = {

      recentf = {
        enable = true;
        config = ''
          (add-to-list 'recentf-exclude "\\Archive\\.org\\'")
          (add-to-list 'recentf-exclude "\\Tasks\\.org\\'")
        '';
      };

      savehist = {
        enable = true;
        init = "(savehist-mode 1)";
      };

      saveplace = {
        enable = true;
        init = "(save-place-mode 1)";
      };

      repeat = {
        enable = true;
        custom = {
          repeat-exit-timeout = 3;
        };
        init = "(repeat-mode 1)";
      };
    };

    prelude = "(context-menu-mode 1)";
  };
}
