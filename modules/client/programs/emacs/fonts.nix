{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.prelude = ''
    (setq swarsel/fixed-font "FiraCode Nerd Font"
          swarsel/variable-font "Iosevka Aile")

    (set-face-attribute 'default nil :font swarsel/fixed-font :height 100)
    (set-face-attribute 'fixed-pitch nil :font swarsel/fixed-font :height 130)
    (set-face-attribute 'variable-pitch nil :font swarsel/variable-font :weight 'light :height 130)
  '';
}
