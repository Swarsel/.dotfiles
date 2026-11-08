{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.prelude = ''
    (setq swarsel/fixed-font "FiraCode Nerd Font"
          swarsel/variable-font "Iosevka Aile")

    (set-face-attribute 'default nil :font swarsel/fixed-font :height 100)
    (set-face-attribute 'fixed-pitch nil :font swarsel/fixed-font :height 130)
    (set-face-attribute 'variable-pitch nil :font swarsel/variable-font :weight 'light :height 130)

    (defun swarsel/use-noto-emoji ()
      (when (display-graphic-p)
        (remove-hook 'server-after-make-frame-hook #'swarsel/use-noto-emoji)
        (run-with-idle-timer 0 nil (lambda ()
                                     (dolist (script '(emoji symbol))
                                       (set-fontset-font t script "Noto Color Emoji" nil 'prepend))))))

    (add-hook 'server-after-make-frame-hook #'swarsel/use-noto-emoji)
    (swarsel/use-noto-emoji)

    (set-char-table-range char-width-table #xFE0F 1)
  '';
}
