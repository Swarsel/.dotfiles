{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.rainbow-mode = {
    enable = true;
    hook = [ "((css-mode css-ts-mode web-mode html-mode html-ts-mode) . rainbow-mode)" ];
  };
}
