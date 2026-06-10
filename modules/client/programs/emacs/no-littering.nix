{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.no-littering = {
    enable = true;
    config = ''
      (setq custom-file (make-temp-file "emacs-custom-"))
      (load custom-file t)
    '';
  };
}
