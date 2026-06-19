{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    rg.enable = true;
    wgrep = {
      enable = true;
      custom = {
        wgrep-auto-save-buffer = true;
      };
    };
  };
}
