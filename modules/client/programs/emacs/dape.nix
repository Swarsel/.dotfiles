{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    dape = {
      enable = true;
      custom = {
        dape-buffer-window-arrangement = "'right";
        dape-inlay-hints = true;
      };
    };
    sideline-flymake = {
      enable = true;
      hook = [ "(flymake-mode . sideline-mode)" ];
      init = ''
        (setq sideline-flymake-display-mode 'point)
          (setq sideline-backends-right '(sideline-flymake))
      '';
    };
  };
}
