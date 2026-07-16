{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.pinentry = {
    config = ''
      (pinentry-start)
      (setq epg-pinentry-mode 'loopback)
    '';
    enable = true;
  };
}
