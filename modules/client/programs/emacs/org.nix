{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    auctex = {
      enable = true;
      custom = {
        LaTeX-electric-left-right-brace = true;
        TeX-auto-save = true;
        TeX-electric-sub-and-superscript = true;
        TeX-engine = "'luatex";
        TeX-master = false;
        TeX-parse-self = true;
        TeX-save-query = false;
        font-latex-fontify-script = false;
      };
      hook = [
        "(LaTeX-mode . visual-line-mode)"
        "(LaTeX-mode . flyspell-mode)"
        "(LaTeX-mode . LaTeX-math-mode)"
        "(LaTeX-mode . reftex-mode)"
      ];
    };
    general.config = ''
      (swarsel/leader-keys
        "o"  '(:ignore o :which-key "org")
        "op" '(org-present :which-key "org-present")
        "oa" '(org-agenda :which-key "org-agenda")
        "or" '(org-refile :which-key "org-refile")
        "ob" '(org-babel-mark-block :which-key "Mark whole src-block")
        "ol" '(org-insert-link :which-key "insert link")
        "oc" '(org-store-link :which-key "copy (=store) link")
        "os" '(shfmt-region :which-key "format sh-block")
        "od" '(org-babel-demarcate-block :which-key "demarcate (split) src-block")
        "on" '(pedantix-format-region :which-key "format nix-block")
        "ot" '(swarsel/org-babel-tangle-config :which-key "tangle file")
        "oe" '(org-html-export-to-html :which-key "export to html")
        "c"  '(:ignore c :which-key "capture")
        "ct" '((lambda () (interactive) (org-capture nil "tt")) :which-key "task")
        "lc" '((lambda () (interactive) (progn (find-file swarsel-swarsel-org-filepath) (org-overview) )) :which-key "SwarselSystems.org")
        "le" '((lambda () (interactive) (progn (find-file swarsel-swarsel-org-filepath) (goto-char (org-find-exact-headline-in-buffer "Emacs") ) (org-overview) (org-cycle) )) :which-key "Emacs.org")
        "ln" '((lambda () (interactive) (progn (find-file swarsel-swarsel-org-filepath) (goto-char (org-find-exact-headline-in-buffer "System") ) (org-overview) (org-cycle))) :which-key "Nixos.org"))

      (general-define-key
       "C-M-a" (lambda () (interactive) (org-capture nil "a"))
       "M-i" 'swarsel/org-insert-link-to-heading)
    '';
    hide-mode-line.enable = true;
    org = {
      config = ''
        (advice-add 'org-unlogged-message :around #'suppress-messages)

        (setq org-ellipsis " ⤵"
              org-link-descriptive t
              org-hide-emphasis-markers t
              org-startup-folded t
              org-support-shift-select t
              org-agenda-start-with-log-mode t
              org-fontify-quote-and-verse-blocks t
              org-log-done 'time
              org-log-into-drawer t
              org-startup-with-inline-images t
              org-export-headline-levels 6
              org-image-actual-width nil
              org-format-latex-options '(:foreground "White" :background default :scale 2.0 :html-foreground "Black" :html-background "Transparent" :html-scale 1.0 :matchers ("begin" "$1" "$" "$$" "\\(" "\\["))
              org-agenda-files '("~/Org/Tasks.org" "~/Org/Archive.org"))

        (setq org-capture-templates
              '(("t" "Todo" entry (file+headline "~/Org/Tasks.org" "Inbox")
                 "* TODO %?\n  %i\n  %a")
                ("j" "Journal" entry (file+olp+datetree "~/Org/Journal.org")
                 "* %?\nEntered on %U\n  %i\n  %a")))

        (setq org-refile-targets
              '((swarsel-archive-org-file :maxlevel . 1)
                (swarsel-tasks-org-file :maxlevel . 1)))

        (org-babel-do-load-languages
         'org-babel-load-languages
         '((emacs-lisp . t)
           (python . t)
           (js . t)
           (shell . t)))

        (set-face-attribute 'org-block nil :foreground 'unspecified :inherit 'fixed-pitch)
        (set-face-attribute 'org-table nil :inherit 'fixed-pitch)
        (set-face-attribute 'org-formula nil :inherit 'fixed-pitch)
        (set-face-attribute 'org-code nil :inherit '(shadow fixed-pitch))
        (set-face-attribute 'org-quote nil :inherit '(shadow fixed-pitch))
        (set-face-attribute 'org-verse nil :inherit '(shadow fixed-pitch))
        (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
        (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
        (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
        (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch)

        (dolist (face '((org-level-1 . 1.2)
                        (org-level-2 . 1.1)
                        (org-level-3 . 1.0)
                        (org-level-4 . 1.0)
                        (org-level-5 . 1.0)
                        (org-level-6 . 1.0)
                        (org-level-7 . 1.0)
                        (org-level-8 . 1.0)))
          (set-face-attribute (car face) nil :font swarsel/variable-font :weight 'medium :height (cdr face)))

        (add-to-list 'org-src-lang-modes '("conf-unix" . conf-unix))

        (define-advice org-src-font-lock-fontify-block (:before (lang _start _end) swarsel/quiet-fontification-buffer)
          (when-let* ((lang-mode (org-src-get-lang-mode-if-bound lang)))
            (with-current-buffer (get-buffer-create (format " *org-src-fontification:%s*" lang-mode))
              (unless (eq major-mode lang-mode)
                (delay-mode-hooks (funcall lang-mode))
                (rainbow-delimiters-mode 1)))))

        (advice-add 'org-babel-tangle-single-block :around #'swarsel/org-babel-tangle-single-block-advice)
        (advice-add 'org-babel-tangle :around #'swarsel/org-babel-tangle-timing-advice)

        (require 'org-tempo)
        (add-to-list 'org-structure-template-alist '("sh" . "src shell"))
        (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
        (add-to-list 'org-structure-template-alist '("py" . "src python :results output"))
        (add-to-list 'org-structure-template-alist '("nix" . "src nix-ts :tangle"))
        (add-to-list 'org-structure-template-alist '("ne" . "bash :exports both"))
      '';
      enable = true;
      bind = {
        "C-<tab>" = "org-fold-outer";
        "C-c s" = "org-store-link";
      };
      custom = {
        org-confirm-babel-evaluate = false;
        org-export-with-broken-links = "'mark";
        org-fold-core-style = "'overlays";
        org-html-htmlize-output-type = false;
        org-src-fontify-natively = true;
        org-src-preserve-indentation = false;
      };
      hook = [ "(org-mode . swarsel/org-mode-setup)" ];
      init = ''
        (defun swarsel/org-mode-setup ()
          (variable-pitch-mode 1)
          (add-hook 'org-tab-first-hook 'org-end-of-line)
          (visual-line-mode 1))

        (defun swarsel/org-mode-visual-fill ()
          (setq visual-fill-column-width 150
                visual-fill-column-center-text t)
          (visual-fill-column-mode 1))

        (defun swarsel/run-formatting ()
          (interactive)
          (let ((default-directory (expand-file-name "~/.dotfiles")))
            (shell-command "find . -name '*.nix' -exec pedantix {} + > /dev/null")))

        (defun swarsel/org-babel-tangle-config ()
          (interactive)
          (when (string-equal (buffer-file-name) swarsel-swarsel-org-filepath)
            (org-babel-tangle)
            (swarsel/run-formatting)))

        (defun swarsel/org-babel-tangle-single-block-advice (orig-fun &rest args)
          (let ((inhibit-redisplay t)
                (inhibit-message t))
            (apply orig-fun args)))

        (defun swarsel/org-babel-tangle-timing-advice (orig-fun &rest args)
          (let ((start (current-time)))
            (prog1 (apply orig-fun args)
              (message "org-tangle took %f sec" (float-time (time-since start))))))

        (defun org-fold-outer ()
          (interactive)
          (org-beginning-of-line)
          (when (org-at-heading-p)
            (outline-up-heading 1))
          (outline-hide-subtree))

        (defun prot-org--id-get ()
          (or (org-entry-get nil "CUSTOM_ID")
              (let ((id (org-id-new "h")))
                (org-entry-put nil "CUSTOM_ID" id)
                id)))

        (defun prot-org-id-headlines ()
          (interactive)
          (org-map-entries #'prot-org--id-get))

        (defun prot-org-id-headline ()
          (interactive)
          (prot-org--id-get))

        (defun swarsel/org-colorize-outline (path)
          (let ((palette ["#58B6ED" "#8BD49C" "#33CED8" "#4B9CCC" "yellow" "orange" "salmon" "red"]))
            (string-join
             (seq-map-indexed (lambda (part depth)
                                (propertize part 'face `(:foreground ,(aref palette (mod depth (length palette))) :weight bold)))
                              path)
             "/")))

        (defun swarsel/org-insert-link-to-heading ()
          (interactive)
          (let* ((candidates (org-map-entries
                              (lambda ()
                                (cons (swarsel/org-colorize-outline (org-get-outline-path t))
                                      (point-marker)))))
                 (marker (cdr (assoc (completing-read "Heading: " candidates nil t) candidates))))
            (insert (org-with-point-at marker
                      (org-link-make-string (concat "#" (prot-org--id-get))
                                            (org-get-heading t t t t))))))

        (defun swarsel/org-agenda-done-and-archive ()
          (interactive)
          (let ((org-archive-location "~/Org/Archive.org::Archive"))
            (org-agenda-todo "DONE")
            (org-agenda-archive)
            (save-some-buffers t (lambda ()
                                   (and buffer-file-name
                                        (file-in-directory-p buffer-file-name "~/Org/"))))))

        (with-eval-after-load 'org-agenda
          (define-key org-agenda-mode-map (kbd "C-a") #'swarsel/org-agenda-done-and-archive))

        (defun org-babel-execute:markdown (body params)
          "Just return BODY unchanged, allowing noweb expansion."
          body)
      '';
    };
    org-appear = {
      enable = true;
      hook = [ "(org-mode . org-appear-mode)" ];
      init = ''
        (setq org-appear-autolinks t
              org-appear-autokeywords t
              org-appear-autoentities t
              org-appear-autosubmarkers t)
      '';
    };
    org-fragtog = {
      enable = true;
      hook = [
        "(org-mode . org-fragtog-mode)"
        "((markdown-mode markdown-ts-mode) . org-fragtog-mode)"
      ];
    };
    org-modern = {
      config = ''
        (setq org-modern-block-name
              '((t . t)
                ("src" "»" "∥")))
      '';
      enable = true;
      custom.org-modern-block-fringe = false;
      hook = [ "(org-mode . org-modern-mode)" ];
    };
    org-present = {
      config = ''
        (setq org-present-startup-folded t)
      '';
      enable = true;
      bindLocal.org-present-mode-keymap = {
        "<left>" = "swarsel/org-present-prev";
        "<right>" = "swarsel/org-present-next";
        q = "org-present-quit";
      };
      hook = [
        "(org-present-mode . swarsel/org-present-start)"
        "(org-present-mode-quit . swarsel/org-present-end)"
      ];
      init = ''
        (defun swarsel/org-reveal-at-point ()
          (when (and (derived-mode-p 'org-mode)
                     (org-at-heading-p))
            (org-show-entry)
            (org-show-children)))

        (defun swarsel/org-present-maybe-read-only ()
          (if (org-in-src-block-p)
              (when buffer-read-only
                (org-present-read-write)
                (evil-insert-state 1))
            (unless buffer-read-only
              (org-present-read-only)
              (evil-insert-state 1))))

        (defun swarsel/org-present-narrow (orig-fn &rest args)
          (cl-letf (((symbol-function 'show-all) #'ignore))
            (apply orig-fn args))
          (org-overview)
          (org-show-entry))

        (advice-add 'org-present-narrow :around #'swarsel/org-present-narrow)

        (defun swarsel/org-present-start ()
          (setq-local face-remapping-alist `((default (:height 1.5) variable-pitch)
                                             (header-line (:height 4.0) variable-pitch)
                                             (org-document-title (:height 2.75) org-document-title)
                                             (org-code (:height 1.2) org-code)
                                             (org-verbatim (:family ,swarsel/fixed-font :height 1.0) org-verbatim)
                                             (org-quote (:height 1.0) org-quote)
                                             (org-verse (:height 1.0) org-verse)
                                             (org-table (:family ,swarsel/fixed-font :weight regular :height 1.0) org-table)
                                             (org-block (:height 0.9) org-block)
                                             (org-link (:underline nil) org-link)
                                             (org-block-begin-line (:height 0.7) org-block)))

          (setq header-line-format " ")
          (setq visual-fill-column-width 150)
          (setq indicate-buffer-boundaries nil)
          (setq inhibit-message nil)
          (setq org-babel-eval-error-notify t)
          (org-display-inline-images)
          (global-hl-line-mode 0)
          (evil-insert-state 1)
          (org-present-read-only)
          (org-overview)
          (add-hook 'post-command-hook #'swarsel/org-reveal-at-point nil t)
          (add-hook 'post-command-hook #'swarsel/org-present-maybe-read-only nil t))

        (defun swarsel/org-present-end ()
          (setq-local face-remapping-alist
                      (append
                       (mapcar (lambda (face) `(,face (:family ,swarsel/fixed-font :weight regular) ,face))
                               '(org-verbatim
                                 org-table
                                 org-meta-line
                                 org-formula
                                 org-checkbox
                                 org-latex-and-related
                                 org-indent
                                 org-code
                                 org-document-info-keyword
                                 org-block-end-line
                                 org-block-begin-line
                                 org-block
                                 mu4e-compose-header-face
                                 mu4e-compose-separator-face
                                 mu4e-contact-face
                                 mu4e-link-face
                                 mu4e-header-value-face
                                 mu4e-header-key-face
                                 message-header-other
                                 message-header-subject
                                 message-header-xheader
                                 message-header-newsgroups
                                 message-header-cc
                                 message-header-to
                                 message-header-name
                                 markdown-math-face
                                 markdown-language-keyword-face
                                 markdown-language-info-face
                                 markdown-inline-code-face
                                 markdown-gfm-checkbox-face
                                 markdown-code-face
                                 line-number-minor-tick
                                 line-number-major-tick
                                 line-number-current-line
                                 line-number
                                 font-lock-variable-name-face
                                 font-lock-type-face
                                 font-lock-string-face
                                 font-lock-regexp-grouping-construct
                                 font-lock-regexp-grouping-backslash
                                 font-lock-preprocessor-face
                                 font-lock-negation-char-face
                                 font-lock-keyword-face
                                 font-lock-function-name-face
                                 font-lock-doc-face
                                 font-lock-constant-face
                                 font-lock-comment-delimiter-face
                                 font-lock-builtin-face
                                 font-latex-sectioning-5-face
                                 font-latex-warning-face
                                 font-latex-sedate-face
                                 font-latex-math-face
                                 diff-removed
                                 diff-hunk-header
                                 diff-header
                                 diff-function
                                 diff-file-header
                                 diff-context
                                 diff-added))
                       '((default (:family "Sans Serif" :weight light) variable-pitch default))))
          (setq header-line-format nil)
          (setq visual-fill-column-width 150)
          (setq indicate-buffer-boundaries t)
          (setq inhibit-message nil)
          (setq org-babel-no-eval-on-error nil)
          (global-hl-line-mode 1)
          (org-remove-inline-images)
          (evil-normal-state 1)
          (remove-hook 'post-command-hook #'swarsel/org-reveal-at-point t)
          (remove-hook 'post-command-hook #'swarsel/org-present-maybe-read-only t))

        (defun swarsel/org-present-prev ()
          (interactive)
          (beginning-of-buffer)
          (org-present-prev)
          (org-overview)
          (org-show-entry)
          (org-show-children))

        (defun swarsel/org-present-next ()
          (interactive)
          (let* ((next-heading (save-excursion
                                 (when (outline-next-heading) (point))))
                 (next-block (save-excursion
                               (when (re-search-forward "^#\\+begin_src" nil t)
                                 (match-beginning 0))))
                 (target (if (and next-heading next-block)
                             (min next-heading next-block)
                           (or next-heading next-block))))
            (if (and target (< target (point-max)))
                (progn
                  (goto-char target)
                  (org-fold-show-entry)
                  (unless (pos-visible-in-window-p (point-max))
                    (recenter 0)))
              (org-present-next))))
      '';
    };
    visual-fill-column = {
      enable = true;
      hook = [
        "(org-mode . swarsel/org-mode-visual-fill)"
        "(markdown-ts-mode . swarsel/org-mode-visual-fill)"
      ];
    };
  };
}
