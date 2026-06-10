{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.vterm = {
    enable = true;
    custom = {
      vterm-tramp-shells = ''
        '(("ssh" "'sh'"))'';
    };
  };
}
