{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    lsp-mode = {
      enable = true;
      init = ''
        (setq lsp-keymap-prefix "C-c l")
        (setq lsp-auto-guess-root "t")

        (cl-defmacro lsp-org-babel-enable (lang)
          "Support LANG in org source code block."
          (setq centaur-lsp 'lsp-mode)
          (cl-check-type lang string)
          (let* ((edit-pre (intern (format "org-babel-edit-prep:%s" lang)))
                 (intern-pre (intern (format "lsp--%s" (symbol-name edit-pre)))))
            `(progn
               (defun ,intern-pre (info)
                 (let ((file-name (->> info caddr (alist-get :file))))
                   (unless file-name
                     (setq file-name (make-temp-file "babel-lsp-")))
                   (setq buffer-file-name file-name)
                   (lsp-deferred)))
               (put ',intern-pre 'function-documentation
                    (format "Enable lsp-mode in the buffer of org source block (%s)."
                            (upcase ,lang)))
               (if (fboundp ',edit-pre)
                   (advice-add ',edit-pre :after ',intern-pre)
                 (progn
                   (defun ,edit-pre (info)
                     (,intern-pre info))
                   (put ',edit-pre 'function-documentation
                        (format "Prepare local buffer environment for org source block (%s)."
                                (upcase ,lang))))))))
        (defvar org-babel-lang-list
          '( "nix" "nix-ts" "go" "python" "ipython" "bash" "sh" ))
        (dolist (lang org-babel-lang-list)
          (eval `(lsp-org-babel-enable ,lang)))
      '';
      command = [ "lsp" ];
      config = ''
        (lsp-register-client
         (make-lsp-client :new-connection (lsp-stdio-connection "nixd")
                          :major-modes '(nix-mode nix-ts-mode)
                          :priority 0
                          :server-id 'nixd))
      '';
    };

    lsp-bridge = {
      enable = true;
      package = "lsp-bridge";
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
