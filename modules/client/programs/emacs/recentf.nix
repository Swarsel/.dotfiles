{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init = {
    prelude = "(context-menu-mode 1)";
    usePackage = {

      recentf = {
        config = ''
          (add-to-list 'recentf-exclude "\\Archive\\.org\\'")
          (add-to-list 'recentf-exclude "\\Tasks\\.org\\'")
        '';
        enable = true;
      };
      repeat = {
        enable = true;
        custom.repeat-exit-timeout = 3;
        init = "(repeat-mode 1)";
      };
      savehist = {
        enable = true;
        init = "(savehist-mode 1)";
      };
      saveplace = {
        enable = true;
        init = "(save-place-mode 1)";
      };
    };
  };
}
