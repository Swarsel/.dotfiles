{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    corfu = {
      enable = true;
      init = ''
        (defun swarsel/corfu-normal-return (&optional arg)
          (interactive)
          (corfu-quit)
          (newline)
          )

        (defun swarsel/corfu-quit-and-up (&optional arg)
          (interactive)
          (corfu-quit)
          (evil-previous-visual-line))

        (defun swarsel/corfu-quit-and-down (&optional arg)
          (interactive)
          (corfu-quit)
          (evil-next-visual-line))

        (global-corfu-mode)
        (corfu-history-mode)
        (corfu-popupinfo-mode)
      '';
      custom = {
        corfu-auto = true;
        corfu-auto-prefix = 3;
        corfu-auto-delay = 1;
        corfu-cycle = true;
        corfu-quit-no-match = "'separator";
        corfu-separator = ''?\s'';
        corfu-popupinfo-max-height = 70;
        corfu-popupinfo-delay = "'(0.5 . 0.2)";
        corfu-preselect = "'prompt";
        corfu-on-exact-match = false;
      };
      bindLocal.corfu-map = {
        "M-SPC" = "corfu-insert-separator";
        "<return>" = "swarsel/corfu-normal-return";
        "S-<up>" = "corfu-popupinfo-scroll-down";
        "S-<down>" = "corfu-popupinfo-scroll-up";
        "C-<up>" = "corfu-previous";
        "C-<down>" = "corfu-next";
        "<insert-state> <up>" = "swarsel/corfu-quit-and-up";
        "<insert-state> <down>" = "swarsel/corfu-quit-and-down";
      };
    };

    nerd-icons-corfu = {
      enable = true;
      after = [ "corfu" ];
      config = ''
        (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter)
        (setq nerd-icons-corfu-mapping
              '((array :style "cod" :icon "symbol_array" :face font-lock-type-face)
                (boolean :style "cod" :icon "symbol_boolean" :face font-lock-builtin-face)
                (t :style "cod" :icon "code" :face font-lock-warning-face)))
      '';
    };
  };
}
