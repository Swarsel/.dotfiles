{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.recentf = {
    enable = true;
    config = ''
      (add-to-list 'recentf-exclude "\\Archive\\.org\\'")
      (add-to-list 'recentf-exclude "\\Tasks\\.org\\'")
    '';
  };
}
