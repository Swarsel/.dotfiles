{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    general.config = ''
      (swarsel/leader-keys
        "o"  '(:ignore o :which-key "org")
        "op" '((lambda () (interactive) (org-present)) :which-key "org-present")
        "oa" '((lambda () (interactive) (org-agenda)) :which-key "org-agenda")
        "oa" '((lambda () (interactive) (org-refile)) :which-key "org-refile")
        "ob" '((lambda () (interactive) (org-babel-mark-block)) :which-key "Mark whole src-block")
        "ol" '((lambda () (interactive) (org-insert-link)) :which-key "insert link")
        "oc" '((lambda () (interactive) (org-store-link)) :which-key "copy (=store) link")
        "os" '(shfmt-region :which-key "format sh-block")
        "od" '((lambda () (interactive) (org-babel-demarcate-block)) :which-key "demarcate (split) src-block")
        "on" '(nixpkgs-fmt-region :which-key "format nix-block")
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

    org = {
      enable = true;
      hook = [ "(org-mode . swarsel/org-mode-setup)" ];
      bind = {
        "C-<tab>" = "org-fold-outer";
        "C-c s" = "org-store-link";
      };
      custom = {
        org-html-htmlize-output-type = false;
        org-fold-core-style = "'overlays";
        org-src-preserve-indentation = false;
        org-src-fontify-natively = true;
        org-export-with-broken-links = "'mark";
        org-confirm-babel-evaluate = false;
      };
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
            (shell-command "nixpkgs-fmt . > /dev/null")))

        (defun swarsel/org-babel-tangle-config ()
          (interactive)
          (when (string-equal (buffer-file-name)
                              swarsel-swarsel-org-filepath)
            (let ((org-confirm-babel-evaluate nil))
              (org-babel-tangle)
              (swarsel/run-formatting)
              )))

        (defun swarsel/org-babel-tangle-single-block-advice (orig-fun &rest args)
          "Run ORIG-FUN with redisplay and messages temporarily inhibited."
          (let ((inhibit-redisplay t)
                (inhibit-message t))
            (apply orig-fun args)))

        (defun swarsel/org-babel-tangle-timing-advice (orig-fun &rest args)
          "Run ORIG-FUN and report elapsed tangle time."
          (let ((tim (current-time)))
            (prog1 (apply orig-fun args)
              (message "org-tangle took %f sec" (float-time (time-subtract (current-time) tim))))))

        (defun org-fold-outer ()
          (interactive)
          (org-beginning-of-line)
          (if (string-match "^*+" (thing-at-point 'line t))
              (outline-up-heading 1))
          (outline-hide-subtree)
          )

        (defun prot-org--id-get ()
          "Get the CUSTOM_ID of the current entry.
        If the entry already has a CUSTOM_ID, return it as-is, else
        create a new one."
          (let* ((pos (point))
                 (id (org-entry-get pos "CUSTOM_ID")))
            (if (and id (stringp id) (string-match-p "\\S-" id))
                id
              (setq id (org-id-new "h"))
              (org-entry-put pos "CUSTOM_ID" id)
              id)))

        (declare-function org-map-entries "org")

        (defun prot-org-id-headlines ()
          "Add missing CUSTOM_ID to all headlines in current file."
          (interactive)
          (org-map-entries
           (lambda () (prot-org--id-get))))

        (defun prot-org-id-headline ()
          "Add missing CUSTOM_ID to headline at point."
          (interactive)
          (prot-org--id-get))

        (defun swarsel/org-colorize-outline (parents raw)
            (let* ((palette ["#58B6ED" "#8BD49C" "#33CED8" "#4B9CCC"
                             "yellow" "orange" "salmon" "red"])
                   (n (length parents))
                   (colored-parents
                    (cl-mapcar
                     (lambda (p i)
                       (propertize p 'face `(:foreground ,(aref palette (mod i (length palette))) :weight bold)))
                     parents
                     (number-sequence 0 (1- n)))))
              (concat
               (when parents
                 (string-join colored-parents "/"))
               (when parents "/")
               (propertize raw 'face `(:foreground ,(aref palette (mod n (length palette)))
                                         :weight bold)))))

        (defun swarsel/org-insert-link-to-heading ()
          (interactive)
          (let ((candidates '()))
            (org-map-entries
             (lambda ()
               (let* ((raw (org-get-heading t t t t))
                      (parents (org-get-outline-path t))
                      (m (copy-marker (point)))
                      (colored (swarsel/org-colorize-outline parents raw)))
                 (push (cons colored m) candidates))))

            (let* ((choice (completing-read "Heading: " (mapcar #'car candidates)))
                   (marker (cdr (assoc choice candidates)))
                   id raw-heading)
              (unless marker
                (user-error "No marker for heading??"))

              (save-excursion
                (goto-char marker)
                (setq id (prot-org--id-get))
                (setq raw-heading (org-get-heading t t t t)))

              (insert (org-link-make-string (format "#%s" id)
                                            raw-heading)))))

        (defun swarsel/org-agenda-done-and-archive ()
          "Mark TODO at point as DONE, archive it, and save all agenda files."
          (interactive)
          (let ((org-archive-location "~/Org/Archive.org::Archive"))
            (org-agenda-todo "DONE")
            (org-agenda-archive)
            (dolist (buf (buffer-list))
              (with-current-buffer buf
                (when (and buffer-file-name
                           (string-prefix-p (expand-file-name "~/Org/") (file-truename buffer-file-name))
                           (derived-mode-p 'org-mode))
                  (save-buffer))))))

        (with-eval-after-load 'org-agenda
          (define-key org-agenda-mode-map (kbd "C-a") #'swarsel/org-agenda-done-and-archive))

        (defun org-babel-execute:markdown (body params)
          "Just return BODY unchanged, allowing noweb expansion."
          body)
      '';
      config = ''
        (advice-add 'org-unlogged-message :around #'suppress-messages)

        (setq org-ellipsis " ⤵"
              org-link-descriptive t
              org-hide-emphasis-markers t)
        (setq org-startup-folded t)
        (setq org-support-shift-select t)

        (setq org-agenda-start-with-log-mode t)
        (setq org-fontify-quote-and-verse-blocks t)
        (setq org-log-done 'time)
        (setq org-log-into-drawer t)
        (setq org-startup-with-inline-images t)
        (setq org-export-headline-levels 6)
        (setq org-image-actual-width nil)
        (setq org-format-latex-options '(:foreground "White" :background default :scale 2.0 :html-foreground "Black" :html-background "Transparent" :html-scale 1.0 :matchers ("begin" "$1" "$" "$$" "\\(" "\\[")))

        (setq org-agenda-files '("/home/swarsel/Org/Tasks.org"
                                 "/home/swarsel/Org/Archive.org"
                                 ))

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

        (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
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

        (advice-add 'org-babel-tangle-single-block :around #'swarsel/org-babel-tangle-single-block-advice)
        (advice-add 'org-babel-tangle :around #'swarsel/org-babel-tangle-timing-advice)

        (require 'org-tempo)
        (add-to-list 'org-structure-template-alist '("sh" . "src shell"))
        (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
        (add-to-list 'org-structure-template-alist '("py" . "src python :results output"))
        (add-to-list 'org-structure-template-alist '("nix" . "src nix-ts :tangle"))
        (add-to-list 'org-structure-template-alist '("ne" . "bash :exports both"))
      '';
    };

    org-appear = {
      enable = true;
      hook = [ "(org-mode . org-appear-mode)" ];
      init = ''
        (setq org-appear-autolinks t)
        (setq org-appear-autokeywords t)
        (setq org-appear-autoentities t)
        (setq org-appear-autosubmarkers t)
      '';
    };

    visual-fill-column = {
      enable = true;
      hook = [ "(org-mode . swarsel/org-mode-visual-fill)" ];
    };

    auctex = {
      enable = true;
      hook = [
        "(LaTeX-mode . visual-line-mode)"
        "(LaTeX-mode . flyspell-mode)"
        "(LaTeX-mode . LaTeX-math-mode)"
        "(LaTeX-mode . reftex-mode)"
      ];
      custom = {
        TeX-auto-save = true;
        TeX-save-query = false;
        TeX-parse-self = true;
        TeX-engine = "'luatex";
        TeX-master = false;
        LaTeX-electric-left-right-brace = true;
        font-latex-fontify-script = false;
        TeX-electric-sub-and-superscript = true;
      };
    };

    org-fragtog = {
      enable = true;
      hook = [
        "(org-mode . org-fragtog-mode)"
        "(markdown-mode . org-fragtog-mode)"
      ];
    };

    org-modern = {
      enable = true;
      config = ''
        (setq org-modern-block-name
              '((t . t)
                ("src" "»" "∥")))
      '';
      hook = [ "(org-mode . org-modern-mode)" ];
    };

    org-present = {
      enable = true;
      bindLocal.org-present-mode-keymap = {
        "q" = "org-present-quit";
        "<left>" = "swarsel/org-present-prev";
        "<​up>" = "'ignore";
        "<​down>" = "'ignore";
        "<right>" = "swarsel/org-present-next";
      };
      hook = [
        "(org-present-mode . swarsel/org-present-start)"
        "(org-present-mode-quit . swarsel/org-present-end)"
      ];
      init = ''
        (defun swarsel/org-reveal-at-point ()
          "Reveal the org entry at point if it is a heading."
          (when (and (derived-mode-p 'org-mode)
                     (org-at-heading-p))
            (org-show-entry)
            (org-show-children)))

        (defun swarsel/org-present-maybe-read-only ()
          "Toggle read-only based on whether cursor is inside a src block."
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
                                             (org-block-begin-line (:height 0.7) org-block)
                                             ))

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
          (add-hook 'post-command-hook #'swarsel/org-present-maybe-read-only nil t)
          )

        (defun swarsel/org-present-end ()
          (setq-local face-remapping-alist `((org-verbatim (:family ,swarsel/fixed-font :weight regular)
                                                           org-verbatim)
                                             (org-table (:family ,swarsel/fixed-font :weight regular) org-table)
                                             (org-meta-line (:family ,swarsel/fixed-font :weight regular) org-meta-line)
                                             (org-formula (:family ,swarsel/fixed-font :weight regular) org-formula)
                                             (org-checkbox (:family ,swarsel/fixed-font :weight regular) org-checkbox)
                                             (org-latex-and-related (:family ,swarsel/fixed-font :weight regular)
                                                                    org-latex-and-related)
                                             (org-indent (:family ,swarsel/fixed-font :weight regular) org-indent)
                                             (org-code (:family ,swarsel/fixed-font :weight regular) org-code)
                                             (org-document-info-keyword (:family ,swarsel/fixed-font :weight regular)
                                                                        org-document-info-keyword)
                                             (org-block-end-line (:family ,swarsel/fixed-font :weight regular) org-block-end-line)
                                             (org-block-begin-line (:family ,swarsel/fixed-font :weight regular)
                                                                   org-block-begin-line)
                                             (org-block (:family ,swarsel/fixed-font :weight regular) org-block)
                                             (mu4e-compose-header-face (:family ,swarsel/fixed-font :weight regular)
                                                                       mu4e-compose-header-face)
                                             (mu4e-compose-separator-face (:family ,swarsel/fixed-font :weight regular)
                                                                          mu4e-compose-separator-face)
                                             (mu4e-contact-face (:family ,swarsel/fixed-font :weight regular) mu4e-contact-face)
                                             (mu4e-link-face (:family ,swarsel/fixed-font :weight regular) mu4e-link-face)
                                             (mu4e-header-value-face (:family ,swarsel/fixed-font :weight regular)
                                                                     mu4e-header-value-face)
                                             (mu4e-header-key-face (:family ,swarsel/fixed-font :weight regular)
                                                                   mu4e-header-key-face)
                                             (message-header-other (:family ,swarsel/fixed-font :weight regular)
                                                                   message-header-other)
                                             (message-header-subject (:family ,swarsel/fixed-font :weight regular)
                                                                     message-header-subject)
                                             (message-header-xheader (:family ,swarsel/fixed-font :weight regular)
                                                                     message-header-xheader)
                                             (message-header-newsgroups (:family ,swarsel/fixed-font :weight regular)
                                                                        message-header-newsgroups)
                                             (message-header-cc (:family ,swarsel/fixed-font :weight regular) message-header-cc)
                                             (message-header-to (:family ,swarsel/fixed-font :weight regular) message-header-to)
                                             (message-header-name (:family ,swarsel/fixed-font :weight regular)
                                                                  message-header-name)
                                             (markdown-math-face (:family ,swarsel/fixed-font :weight regular) markdown-math-face)
                                             (markdown-language-keyword-face (:family ,swarsel/fixed-font :weight regular)
                                                                             markdown-language-keyword-face)
                                             (markdown-language-info-face (:family ,swarsel/fixed-font :weight regular)
                                                                          markdown-language-info-face)
                                             (markdown-inline-code-face (:family ,swarsel/fixed-font :weight regular)
                                                                        markdown-inline-code-face)
                                             (markdown-gfm-checkbox-face (:family ,swarsel/fixed-font :weight regular)
                                                                         markdown-gfm-checkbox-face)
                                             (markdown-code-face (:family ,swarsel/fixed-font :weight regular) markdown-code-face)
                                             (line-number-minor-tick (:family ,swarsel/fixed-font :weight regular)
                                                                     line-number-minor-tick)
                                             (line-number-major-tick (:family ,swarsel/fixed-font :weight regular)
                                                                     line-number-major-tick)
                                             (line-number-current-line (:family ,swarsel/fixed-font :weight regular)
                                                                       line-number-current-line)
                                             (line-number (:family ,swarsel/fixed-font :weight regular) line-number)
                                             (font-lock-variable-name-face (:family ,swarsel/fixed-font :weight regular)
                                                                           font-lock-variable-name-face)
                                             (font-lock-type-face (:family ,swarsel/fixed-font :weight regular)
                                                                  font-lock-type-face)
                                             (font-lock-string-face (:family ,swarsel/fixed-font :weight regular)
                                                                    font-lock-string-face)
                                             (font-lock-regexp-grouping-construct (:family ,swarsel/fixed-font :weight regular)
                                                                                  font-lock-regexp-grouping-construct)
                                             (font-lock-regexp-grouping-backslash (:family ,swarsel/fixed-font :weight regular)
                                                                                  font-lock-regexp-grouping-backslash)
                                             (font-lock-preprocessor-face (:family ,swarsel/fixed-font :weight regular)
                                                                          font-lock-preprocessor-face)
                                             (font-lock-negation-char-face (:family ,swarsel/fixed-font :weight regular)
                                                                           font-lock-negation-char-face)
                                             (font-lock-keyword-face (:family ,swarsel/fixed-font :weight regular)
                                                                     font-lock-keyword-face)
                                             (font-lock-function-name-face (:family ,swarsel/fixed-font :weight regular)
                                                                           font-lock-function-name-face)
                                             (font-lock-doc-face (:family ,swarsel/fixed-font :weight regular) font-lock-doc-face)
                                             (font-lock-constant-face (:family ,swarsel/fixed-font :weight regular)
                                                                      font-lock-constant-face)
                                             (font-lock-comment-delimiter-face (:family ,swarsel/fixed-font :weight regular)
                                                                               font-lock-comment-delimiter-face)
                                             (font-lock-builtin-face (:family ,swarsel/fixed-font :weight regular)
                                                                     font-lock-builtin-face)
                                             (font-latex-sectioning-5-face (:family ,swarsel/fixed-font :weight regular)
                                                                           font-latex-sectioning-5-face)
                                             (font-latex-warning-face (:family ,swarsel/fixed-font :weight regular)
                                                                      font-latex-warning-face)
                                             (font-latex-sedate-face (:family ,swarsel/fixed-font :weight regular)
                                                                     font-latex-sedate-face)
                                             (font-latex-math-face (:family ,swarsel/fixed-font :weight regular)
                                                                   font-latex-math-face)
                                             (diff-removed (:family ,swarsel/fixed-font :weight regular) diff-removed)
                                             (diff-hunk-header (:family ,swarsel/fixed-font :weight regular) diff-hunk-header)
                                             (diff-header (:family ,swarsel/fixed-font :weight regular) diff-header)
                                             (diff-function (:family ,swarsel/fixed-font :weight regular) diff-function)
                                             (diff-file-header (:family ,swarsel/fixed-font :weight regular) diff-file-header)
                                             (diff-context (:family ,swarsel/fixed-font :weight regular) diff-context)
                                             (diff-added (:family ,swarsel/fixed-font :weight regular) diff-added)
                                             (default (:family "Sans Serif" :weight light) variable-pitch default)
                                             ))
          (setq header-line-format nil)
          (setq visual-fill-column-width 150)
          (setq indicate-buffer-boundaries t)
          (setq inhibit-message nil)
          (setq org-babel-no-eval-on-error nil)
          (global-hl-line-mode 1)
          (org-remove-inline-images)
          (evil-normal-state 1)
          (remove-hook 'post-command-hook #'swarsel/org-reveal-at-point t)
          (remove-hook 'post-command-hook #'swarsel/org-present-maybe-read-only t)
          )

        (defun swarsel/org-present-slide-open ()
          (org-overview)
          (org-show-entry)
          (org-show-children)
          )

        (defun swarsel/org-present-prev ()
          (interactive)
          (beginning-of-buffer)
          (org-present-prev)
          (swarsel/org-present-slide-open)
          )

        (defun swarsel/org-present-next ()
          (interactive)
          (let* ((next-heading (save-excursion
                                 (when (outline-next-heading) (point))))
                 (next-block (save-excursion
                               (when (re-search-forward "^#\\+begin_src" nil t)
                                 (match-beginning 0))))
                 (target (cond
                          ((and next-heading next-block) (min next-heading next-block))
                          (next-heading next-heading)
                          (next-block next-block)
                          (t nil))))
            (if (and target (< target (point-max)))
                (progn
                  (goto-char target)
                  (org-fold-show-entry)
                  (unless (pos-visible-in-window-p (point-max))
                    (recenter 0)))
              (org-present-next))))
      '';
      config = ''
        (add-hook 'org-present-after-navigate-functions #'swarsel/org-present-slide)
        (setq org-present-startup-folded t)
      '';
    };

    hide-mode-line.enable = true;
  };
}
