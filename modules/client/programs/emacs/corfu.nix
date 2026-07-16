{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    corfu = {
      enable = true;
      bindLocal.corfu-map = {
        "<insert-state> <down>" = "swarsel/corfu-quit-and-down";
        "<insert-state> <up>" = "swarsel/corfu-quit-and-up";
        "<return>" = "swarsel/corfu-normal-return";
        "C-<down>" = "corfu-next";
        "C-<up>" = "corfu-previous";
        "M-SPC" = "corfu-insert-separator";
        "S-<down>" = "corfu-popupinfo-scroll-up";
        "S-<up>" = "corfu-popupinfo-scroll-down";
      };
      custom = {
        corfu-auto = true;
        corfu-auto-delay = 1;
        corfu-auto-prefix = 3;
        corfu-cycle = true;
        corfu-on-exact-match = false;
        corfu-popupinfo-delay = "'(0.5 . 0.2)";
        corfu-popupinfo-max-height = 70;
        corfu-preselect = "'prompt";
        corfu-quit-no-match = "'separator";
        corfu-separator = ''?\s'';
      };
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
    };

    nerd-icons-corfu = {
      config = ''
        (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter)
        (setq nerd-icons-corfu-mapping
              '((array :style "cod" :icon "symbol_array" :face font-lock-type-face)
                (boolean :style "cod" :icon "symbol_boolean" :face font-lock-builtin-face)
                (t :style "cod" :icon "code" :face font-lock-warning-face)))
      '';
      enable = true;
      after = [ "corfu" ];
    };
  };
}
