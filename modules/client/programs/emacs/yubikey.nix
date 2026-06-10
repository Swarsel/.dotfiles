{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.pinentry = {
    enable = true;
    config = ''
      (pinentry-start)
      (setq epg-pinentry-mode 'loopback)
    '';
  };
}
