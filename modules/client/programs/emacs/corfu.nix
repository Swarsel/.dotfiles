{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    corfu = {
      config = ''
        (dolist (key '("M-n" "M-p"
                       "<remap> <next-line>" "<remap> <previous-line>"
                       "<remap> <scroll-down-command>" "<remap> <scroll-up-command>"
                       "<remap> <beginning-of-buffer>" "<remap> <end-of-buffer>"))
          (keymap-unset corfu-map key t))
        (dolist (command '(swarsel/corfu-insert-or-newline swarsel/corfu-insert-or-expand))
          (add-to-list 'corfu-continue-commands command))
      '';
      enable = true;
      bindLocal.corfu-map = {
        "<down>" = "swarsel/corfu-quit-and-down";
        "<return>" = "swarsel/corfu-insert-or-newline";
        "<up>" = "swarsel/corfu-quit-and-up";
        "C-<down>" = "corfu-next";
        "C-<up>" = "corfu-previous";
        M-SPC = "corfu-insert-separator";
        "S-<down>" = "corfu-popupinfo-scroll-up";
        "S-<up>" = "corfu-popupinfo-scroll-down";
        TAB = "swarsel/corfu-insert-or-expand";
      };
      custom = {
        corfu-auto = true;
        corfu-auto-delay = 0.2;
        corfu-auto-prefix = 2;
        corfu-cycle = true;
        corfu-on-exact-match = false;
        corfu-popupinfo-delay = "'(0.5 . 0.2)";
        corfu-popupinfo-max-height = 70;
        corfu-preselect = "'prompt";
        corfu-quit-no-match = "'separator";
        corfu-separator = ''?\s'';
      };
      init = ''
        (defun swarsel/corfu-insert-or-newline ()
          (interactive)
          (if (>= corfu--index 0)
              (corfu-insert)
            (corfu-quit)
            (newline)))

        (defun swarsel/corfu-insert-or-expand ()
          (interactive)
          (if (>= corfu--index 0)
              (corfu-insert)
            (corfu-expand)))

        (defun swarsel/corfu-quit-and-up (&optional arg)
          (interactive)
          (corfu-quit)
          (evil-previous-visual-line))

        (defun swarsel/corfu-quit-and-down (&optional arg)
          (interactive)
          (corfu-quit)
          (evil-next-visual-line))

        (defun swarsel/corfu-evil-keys (mode _keymaps)
          (when (eq mode 'corfu)
            (evil-define-key* 'insert corfu-map
                              (kbd "<escape>") #'corfu-quit
                              (kbd "C-d") nil
                              (kbd "C-u") nil)))

        (add-hook 'evil-collection-setup-hook #'swarsel/corfu-evil-keys)

        (global-corfu-mode)
        (corfu-history-mode)
        (corfu-popupinfo-mode)
      '';
    };

    evil-collection.custom.evil-collection-corfu-key-themes = false;

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
