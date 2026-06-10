{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.envrc = {
    enable = true;
    hook = [ "(after-init . envrc-global-mode)" ];
  };
}
