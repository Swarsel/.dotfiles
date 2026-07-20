{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init = {
    prelude = ''
      (setq read-buffer-completion-ignore-case t
            read-file-name-completion-ignore-case t
            completion-ignore-case t)

      (defun up-directory (path)
        "Move up a directory in PATH without affecting the kill buffer."
        (interactive "p")
        (if (string-match-p "/." (minibuffer-contents))
            (let ((end (point)))
              (re-search-backward "/.")
              (forward-char)
              (delete-region (point) end))))

      (define-key minibuffer-local-filename-completion-map
                  [C-backspace] #'up-directory)
    '';

    usePackage = {
      consult = {
        enable = true;
        bind = {
          "C-M-j" = "consult-buffer";
          "C-c <C-m>" = "consult-global-mark";
          "C-c C-a" = "consult-org-agenda";
          "C-s" = "consult-line";
          "C-x O" = "consult-org-heading";
          "C-x b" = "consult-buffer";
          "M-g M-g" = "consult-goto-line";
          "M-g i" = "consult-imenu";
          "M-s M-s" = "consult-line-multi";
        };
        bindLocal.minibuffer-local-map = {
          "C-j" = "next-line";
          "C-k" = "previous-line";
        };
        custom.consult-fontify-max-size = 1024;
      };
      consult-dir = {
        enable = true;
        after = [ "consult" ];
        bind."C-x C-d" = "consult-dir";
        bindLocal.minibuffer-local-map = {
          "C-x C-d" = "consult-dir";
          "C-x C-j" = "consult-dir-jump-file";
        };
      };
      consult-eglot = {
        enable = true;
        after = [
          "consult"
          "eglot"
        ];
        bind."C-c s" = "consult-eglot-symbols";
      };
      embark = {
        config = ''
          (add-to-list 'display-buffer-alist
                       '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                         nil
                         (window-parameters (mode-line-format . none))))
        '';
        enable = true;
        bind = {
          "C-." = "embark-act";
          "C-c c" = "embark-collect";
          "C-h B" = "embark-bindings";
          "M-." = "embark-dwim";
        };
        custom = {
          embark-quit-after-action = "'((t . nil))";
          prefix-help-command = "#'embark-prefix-help-command";
        };
      };
      embark-consult = {
        enable = true;
        after = [
          "embark"
          "consult"
        ];
        demand = true;
        hook = [ "(embark-collect-mode . consult-preview-at-point-mode)" ];
      };
      marginalia = {
        enable = true;
        after = [ "vertico" ];
        bindLocal.minibuffer-local-map."M-A" = "marginalia-cycle";
        init = "(marginalia-mode)";
      };
      nerd-icons-completion = {
        enable = true;
        after = [
          "marginalia"
          "nerd-icons"
        ];
        hook = [ "(marginalia-mode . nerd-icons-completion-marginalia-setup)" ];
        init = "(nerd-icons-completion-mode)";
      };
      orderless = {
        config = ''
          (orderless-define-completion-style orderless+initialism
            (orderless-matching-styles '(orderless-initialism orderless-literal orderless-regexp)))
          (setq completion-styles '(orderless)
                completion-category-defaults nil
                completion-category-overrides
                '((file (styles partial-completion orderless+initialism))
                  (buffer (styles orderless+initialism))
                  (consult-multi (styles orderless+initialism))
                  (command (styles orderless+initialism))
                  (eglot (styles orderless+initialism))
                  (variable (styles orderless+initialism))
                  (symbol (styles orderless+initialism)))
                orderless-matching-styles '(orderless-literal orderless-regexp))
        '';
        enable = true;
      };
      vertico = {
        enable = true;
        custom = {
          vertico-count = 10;
          vertico-cycle = true;
          vertico-resize = true;
          vertico-scroll-margin = 0;
        };
        init = ''
          (vertico-mode)
          (vertico-mouse-mode)
        '';
      };
      vertico-directory = {
        enable = true;
        after = [ "vertico" ];
        bindLocal.vertico-map = {
          "C-DEL" = "vertico-directory-delete-word";
          "DEL" = "vertico-directory-delete-char";
          "RET" = "vertico-directory-enter";
        };
        hook = [ "(rfn-eshadow-update-overlay . vertico-directory-tidy)" ];
      };
    };
  };
}
