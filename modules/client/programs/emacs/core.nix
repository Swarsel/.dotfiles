{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init = {
    enable = true;
    recommendedGcSettings = false;

    prelude = ''
      (global-set-key (kbd "<escape>") 'keyboard-escape-quit)

      (global-unset-key (kbd "C-z"))

      (setq
       swarsel-emacs-directory "~/.emacs.d"
       swarsel-dotfiles-directory (getenv "FLAKE")
       swarsel-swarsel-org-filepath (expand-file-name "SwarselSystems.org" swarsel-dotfiles-directory)
       swarsel-tasks-org-file "Tasks.org"
       swarsel-archive-org-file "Archive.org"
       swarsel-work-projects-directory (getenv "DOCUMENT_DIR_WORK")
       swarsel-private-projects-directory (getenv "DOCUMENT_DIR_PRIV")
       )

      (setq user-emacs-directory (expand-file-name "~/.cache/emacs/")
            url-history-file (expand-file-name "url/history" user-emacs-directory))

      (let ((backup-dir "~/tmp/emacs/backups")
            (auto-saves-dir "~/tmp/emacs/auto-saves/"))
        (dolist (dir (list backup-dir auto-saves-dir))
          (when (not (file-directory-p dir))
            (make-directory dir t)))
        (setq backup-directory-alist `(("." . ,backup-dir))
              auto-save-file-name-transforms `((".*" ,auto-saves-dir t))
              auto-save-list-file-prefix (concat auto-saves-dir ".saves-")
              tramp-backup-directory-alist `((".*" . ,backup-dir))
              tramp-auto-save-directory auto-saves-dir))

      (setq backup-by-copying t
            delete-old-versions t
            version-control t
            kept-new-versions 5
            kept-old-versions 2
            backup-by-copying-when-linked t)

      (set-language-environment "UTF-8")

      (add-hook 'before-save-hook 'delete-trailing-whitespace)
      (global-hl-line-mode 1)
      (blink-cursor-mode -1)
      (global-subword-mode 1)
      (setq blink-matching-paren nil)
      (delete-selection-mode 1)
      (setq vc-follow-symlinks t)
      (setq require-final-newline t)
      (winner-mode 1)
      (setq load-prefer-newer t)
      (setq-default bidi-paragraph-direction 'left-to-right
                    bidi-display-reordering 'left-to-right
                    bidi-inhibit-bpa t)
      (global-so-long-mode)
      (setq fast-but-imprecise-scrolling t
            redisplay-skip-fontification-on-input t
            inhibit-compacting-font-caches t)
      (setq idle-update-delay 1.0
            which-func-update-delay 1.0)
      (setq undo-limit 80000000
            evil-want-fine-undo t
            auto-save-default t)
      (setq browse-url-browser-function 'browse-url-firefox)
      (global-set-key [remap suspend-frame]
                      (lambda ()
                        (interactive)
                        (message "This keybinding is disabled (was 'suspend-frame')")))

      (setq visible-bell nil)
      (setq initial-major-mode 'fundamental-mode
            initial-scratch-message nil)

      (add-hook 'prog-mode-hook 'display-line-numbers-mode)

      (setq custom-safe-themes t)

      (setq byte-compile-warnings '(not free-vars unresolved noruntime lexical make-local))
      (when (native-comp-available-p)
        (setq native-comp-async-report-warnings-errors 'silent)
        (setq native-compile-prune-cache t))

      (setq garbage-collection-messages nil)
      (defmacro k-time (&rest body)
        "Measure and return the time it takes evaluating BODY."
        `(let ((time (current-time)))
           ,@body
           (float-time (time-since time))))

      (defvar k-gc-timer
        (run-with-idle-timer 15 t
                             (lambda ()
                               (k-time (garbage-collect)))))

      (defun swarsel/minibuffer-setup-hook ()
        (setq gc-cons-threshold most-positive-fixnum))

      (defun swarsel/minibuffer-exit-hook ()
        (setq gc-cons-threshold (* 100 1024 1024)))

      (add-hook 'minibuffer-setup-hook #'swarsel/minibuffer-setup-hook)
      (add-hook 'minibuffer-exit-hook #'swarsel/minibuffer-exit-hook)

      (setq ispell-alternate-dictionary (getenv "WORDLIST"))

      (setq-default indicate-buffer-boundaries t)

      (setq auth-sources '( "~/.emacs.d/.authinfo")
            auth-source-cache-expiry nil)

      (defun swarsel/with-buffer-name-prompt-and-make-subdirs ()
        (let ((parent-directory (file-name-directory buffer-file-name)))
          (when (and (not (file-exists-p parent-directory))
                     (y-or-n-p (format "Directory `%s' does not exist! Create it? " parent-directory)))
            (make-directory parent-directory t))))

      (add-to-list 'find-file-not-found-functions #'swarsel/with-buffer-name-prompt-and-make-subdirs)

      (defun suppress-messages (old-fun &rest args)
        (cl-flet ((silence (&rest args1) (ignore)))
          (advice-add 'message :around #'silence)
          (unwind-protect
              (apply old-fun args)
            (advice-remove 'message #'silence))))

      (advice-add 'push-mark :around #'suppress-messages)

      (defun who-called-me? (old-fun format &rest args)
        (let ((trace nil) (n 1) (frame nil))
          (while (setf frame (backtrace-frame n))
            (setf n     (1+ n)
                  trace (cons (cadr frame) trace)) )
          (apply old-fun (concat "<<%S>>\n" format) (cons trace args))))

      (advice-remove 'message #'who-called-me?)
    '';
  };
}
