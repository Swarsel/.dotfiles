{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.avy = {
    enable = true;
    bind."M-o" = "avy-goto-char-timer";
    custom.avy-all-windows = "'all-frames";
  };
}
