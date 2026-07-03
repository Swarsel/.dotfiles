;;; hm-init.el --- Emacs configuration à la Home Manager -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; A configuration generated from a Nix based configuration by
;; Home Manager.
;;
;;; Code:



(setq treesit-enabled-modes t)

(setq mouse-wheel-scroll-amount
  '(1
     ((shift) . 5)
     ((meta) . 0.5)
     ((control) . text-scale))
  mouse-drag-copy-region nil
  make-pointer-invisible t
  mouse-wheel-follow-mouse t)

(setq-default scroll-preserve-screen-position t
  next-screen-context-lines 0)

(context-menu-mode 1)
(defun prot-window-delete-popup-frame (&rest _)
  "Kill selected selected frame if it has parameter `prot-window-popup-frame'.
    Use this function via a hook."
  (when (frame-parameter nil 'prot-window-popup-frame)
    (delete-frame)))

(defmacro prot-window-define-with-popup-frame (command)
  "Define interactive function which calls COMMAND in a new frame.
Make the new frame have the `prot-window-popup-frame' parameter."
  `(defun ,(intern (format "prot-window-popup-%s" command)) ()
     ,(format "Run `%s' in a popup frame with `prot-window-popup-frame' parameter.
Also see `prot-window-delete-popup-frame'." command)
     (interactive)
     (let ((frame (make-frame '((prot-window-popup-frame . t)
                                 (title . "Emacs Popup Frame")))))
       (unwind-protect
         (progn
           (select-frame frame)
           (switch-to-buffer " prot-window-hidden-buffer-for-popup-frame")
           (condition-case nil
             (call-interactively ',command)
             ((quit error user-error)
               (delete-frame frame))))
         (dolist (fr (frame-list))
           (when (string= (frame-parameter fr 'name) "Emacs Popup Anchor")
             (delete-frame fr)))))))

(declare-function org-capture "org-capture" (&optional goto keys))
(defvar org-capture-after-finalize-hook)
(prot-window-define-with-popup-frame org-capture)
(add-hook 'org-capture-after-finalize-hook #'prot-window-delete-popup-frame)

(declare-function mu4e "mu4e" (&optional goto keys))
(prot-window-define-with-popup-frame mu4e)
(advice-add 'mu4e-quit :after #'prot-window-delete-popup-frame)

(declare-function swarsel/open-calendar "swarsel/open-calendar" (&optional goto keys))
(prot-window-define-with-popup-frame swarsel/open-calendar)
(advice-add 'bury-buffer :after #'prot-window-delete-popup-frame)

(declare-function org-agenda "org-agenda" (&optional goto keys))
(prot-window-define-with-popup-frame org-agenda)

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

(setq message-log-max 30)
(setq comint-buffer-maximum-size 50)
(add-hook 'comint-output-filter-functions 'comint-truncate-buffer)

(setq-default indent-tabs-mode nil
  tab-width 2)

(setq tab-always-indent 'complete)

(setq swarsel/fixed-font "FiraCode Nerd Font"
  swarsel/variable-font "Iosevka Aile")

(set-face-attribute 'default nil :font swarsel/fixed-font :height 100)
(set-face-attribute 'fixed-pitch nil :font swarsel/fixed-font :height 130)
(set-face-attribute 'variable-pitch nil :font swarsel/variable-font :weight 'light :height 130)

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
(setq kill-region-dwim 'emacs-word)
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
(setq browse-url-browser-function 'browse-url-generic
  browse-url-generic-program "glide")
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
  (setq native-comp-async-on-battery-power nil)
  (setq native-compile-prune-cache t))

(setq garbage-collection-messages nil)
(defmacro k-time (&rest body)
  "Measure and return the time it takes evaluating BODY."
  `(let ((time (current-time)))
     ,@body
     (float-time (time-since time))))

(unless (featurep 'mps)
  (defvar k-gc-timer
    (run-with-idle-timer 15 t
      (lambda ()
        (k-time (garbage-collect)))))

  (defun swarsel/minibuffer-setup-hook ()
    (setq gc-cons-threshold most-positive-fixnum))

  (defun swarsel/minibuffer-exit-hook ()
    (setq gc-cons-threshold (* 100 1024 1024)))

  (add-hook 'minibuffer-setup-hook #'swarsel/minibuffer-setup-hook)
  (add-hook 'minibuffer-exit-hook #'swarsel/minibuffer-exit-hook))

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

(defun swarsel/kill-buffer-delete-window ()
  (let ((win (get-buffer-window (current-buffer))))
    (when (and win (not (one-window-p)))
      (delete-window win))))

(add-hook 'kill-buffer-hook #'swarsel/kill-buffer-delete-window)


(eval-when-compile
  (require 'use-package)
  ;; To help fixing issues during startup.
  (setq use-package-verbose nil))

;; For :diminish in (use-package).
(require 'diminish)
;; For :bind in (use-package).
(require 'bind-key)

;; Fixes "Symbol’s function definition is void: use-package-autoload-keymap".
(autoload #'use-package-autoload-keymap "use-package-bind-key")

(use-package ansible)

(use-package apheleia
  :config
  (apheleia-global-mode 1))

(use-package auctex
  :hook (LaTeX-mode . visual-line-mode)
  :hook (LaTeX-mode . flyspell-mode)
  :hook (LaTeX-mode . LaTeX-math-mode)
  :hook (LaTeX-mode . reftex-mode)
  :custom
  (LaTeX-electric-left-right-brace t)
  (TeX-auto-save t)
  (TeX-electric-sub-and-superscript t)
  (TeX-engine 'luatex)
  (TeX-master nil)
  (TeX-parse-self t)
  (TeX-save-query nil)
  (font-latex-fontify-script nil))

(use-package avy
  :bind (
          ("M-o" . avy-goto-char-timer)
          )
  :custom
  (avy-all-windows 'all-frames))

(use-package calfw
  :bind (
          ("C-c A" . swarsel/open-calendar)
          )
  :init
  (defun swarsel/open-calendar ()
    (interactive)
    (cfw:open-calendar-buffer
      :contents-sources
      (list
        (cfw:org-create-source "Blue")
        (cfw:ical-create-source (getenv "SWARSEL_CAL1NAME") (getenv "SWARSEL_CAL1") "Cyan")
        (cfw:ical-create-source (getenv "SWARSEL_CAL2NAME") (getenv "SWARSEL_CAL2") "Green")
        (cfw:ical-create-source (getenv "SWARSEL_CAL3NAME") (getenv "SWARSEL_CAL3") "Magenta")
        )))

  (require 'calfw-cal)
  (require 'calfw-org)
  (require 'calfw-ical)

  :config
  (bind-key "g" 'cfw:refresh-calendar-buffer cfw:calendar-mode-map)
  (bind-key "q" 'evil-quit cfw:details-mode-map)
  (setq calendar-day-name-array
    ["Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday"])

  (setq calendar-week-start-day 1)
  )

(use-package cape
  :bind (
          ("C-z &" . cape-sgml)
          ("C-z :" . cape-emoji)
          ("C-z \\" . cape-tex)
          ("C-z ^" . cape-tex)
          ("C-z _" . cape-tex)
          ("C-z a" . cape-abbrev)
          ("C-z d" . cape-dabbrev)
          ("C-z e" . cape-elisp-block)
          ("C-z f" . cape-file)
          ("C-z h" . cape-history)
          ("C-z k" . cape-keyword)
          ("C-z l" . cape-line)
          ("C-z p" . completion-at-point)
          ("C-z r" . cape-rfc1345)
          ("C-z s" . cape-elisp-symbol)
          ("C-z t" . complete-tag)
          ("C-z w" . cape-dict)
          ))

(use-package claude-code-ide
  :bind (
          ("C-c c" . claude-code-ide-menu)
          )
  :config
  (claude-code-ide-emacs-tools-setup)

  (defun diego--vterm-font-setup ()
    "Configure font settings specifically for vterm buffers, workaround claude-code."
    (let ((tbl (or buffer-display-table (setq buffer-display-table (make-display-table)))))
      (dolist (pair
                '((#x273B . ?*)
                   (#x273D . ?*)
                   (#x2722 . ?+)
                   (#x2736 . ?+)
                   (#x2733 . ?*)
                   ))
        (aset tbl (car pair) (vector (cdr pair))))))

  (add-hook 'vterm-mode-hook #'diego--vterm-font-setup)
  )

(use-package consult
  :bind (
          ("C-M-j" . consult-buffer)
          ("C-c <C-m>" . consult-global-mark)
          ("C-c C-a" . consult-org-agenda)
          ("C-s" . consult-line)
          ("C-x O" . consult-org-heading)
          ("C-x b" . consult-buffer)
          ("M-g M-g" . consult-goto-line)
          ("M-g i" . consult-imenu)
          ("M-s M-s" . consult-line-multi)
          )
  :bind (:map minibuffer-local-map
          ("C-j" . next-line)
          ("C-k" . previous-line)
          )
  :custom
  (consult-fontify-max-size 1024))

(use-package consult-dir
  :after (consult)
  :bind (
          ("C-x C-d" . consult-dir)
          )
  :bind (:map minibuffer-local-map
          ("C-x C-d" . consult-dir)
          ("C-x C-j" . consult-dir-jump-file)
          ))

(use-package consult-eglot
  :after (consult eglot)
  :bind (
          ("C-c s" . consult-eglot-symbols)
          ))

(use-package corfu
  :bind (:map corfu-map
          ("<insert-state> <down>" . swarsel/corfu-quit-and-down)
          ("<insert-state> <up>" . swarsel/corfu-quit-and-up)
          ("<return>" . swarsel/corfu-normal-return)
          ("C-<down>" . corfu-next)
          ("C-<up>" . corfu-previous)
          ("M-SPC" . corfu-insert-separator)
          ("S-<down>" . corfu-popupinfo-scroll-up)
          ("S-<up>" . corfu-popupinfo-scroll-down)
          )
  :custom
  (corfu-auto t)
  (corfu-auto-delay 1)
  (corfu-auto-prefix 3)
  (corfu-cycle t)
  (corfu-on-exact-match nil)
  (corfu-popupinfo-delay '(0.5 . 0.2))
  (corfu-popupinfo-max-height 70)
  (corfu-preselect 'prompt)
  (corfu-quit-no-match 'separator)
  (corfu-separator ?\s)
  :init
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
  )

(use-package dape
  :custom
  (dape-buffer-window-arrangement 'right)
  (dape-inlay-hints t))

(use-package dashboard
  :config
  (dashboard-setup-startup-hook)

  (let ((files-domain (getenv "SWARSEL_FILES_DOMAIN"))
         (music-domain (getenv "SWARSEL_MUSIC_DOMAIN"))
         (insta-domain (getenv "SWARSEL_INSTA_DOMAIN"))
         (sport-domain (getenv "SWARSEL_SPORT_DOMAIN"))
         (swarsel-domain (getenv "SWARSEL_DOMAIN"))
         )
    (setq dashboard-display-icons-p t
      dashboard-icon-type 'nerd-icons
      dashboard-set-file-icons t
      dashboard-items '((recents . 5)
                         (projects . 5)
                         (agenda . 5))
      dashboard-set-footer nil
      dashboard-banner-logo-title "Welcome to SwarsEmacs!"
      dashboard-image-banner-max-height 300
      dashboard-startup-banner "~/.dotfiles/files/icons/swarsel.png"
      dashboard-projects-backend 'projectile
      dashboard-projects-switch-function 'magit-status
      dashboard-set-navigator t
      dashboard-startupify-list '(dashboard-insert-banner
                                   dashboard-insert-newline
                                   dashboard-insert-banner-title
                                   dashboard-insert-newline
                                   dashboard-insert-navigator
                                   dashboard-insert-newline
                                   dashboard-insert-init-info
                                   dashboard-insert-items
                                   )
      dashboard-navigator-buttons
      `(;; line1
         ((,(char-to-string #xf16d)
            "SwarselSocial"
            "Browse Swarsele"
            (lambda (&rest _) (browse-url ,insta-domain)))

           (,(char-to-string #xf001)
             "SwarselSound"
             "Browse SwarselSound"
             (lambda (&rest _) (browse-url ,(concat "https://" music-domain))) )
           (,(char-to-string #xf09b)
             "SwarselSwarsel"
             "Browse Swarsel"
             (lambda (&rest _) (browse-url "https://github.com/Swarsel")) )
           (,(char-to-string #xebaa)
             "SwarselStash"
             "Browse SwarselStash"
             (lambda (&rest _) (browse-url ,(concat "https://" files-domain))) )
           (,(char-to-string #xf0ad1)
             "SwarselSport"
             "Browse SwarselSports"
             (lambda (&rest _) (browse-url ,sport-domain)))
           )
         (
           (,(char-to-string #xf1105)
             ,swarsel-domain
             ,(concat "Browse " swarsel-domain)
             (lambda (&rest _) (browse-url ,(concat "https://" swarsel-domain))))
           )
         )))
  )

(use-package devdocs
  :hook (python-mode . (lambda () (setq-local devdocs-current-docs '("python~3.12" "numpy~1.23" "matplotlib~3.7" "pandas~1"))))
  :hook (python-ts-mode . (lambda () (setq-local devdocs-current-docs '("python~3.12" "numpy~1.23" "matplotlib~3.7" "pandas~1"))))
  :hook (c-mode . (lambda () (setq-local devdocs-current-docs '("c"))))
  :hook (c-ts-mode . (lambda () (setq-local devdocs-current-docs '("c"))))
  :hook (c++-mode . (lambda () (setq-local devdocs-current-docs '("cpp"))))
  :hook (c++-ts-mode . (lambda () (setq-local devdocs-current-docs '("cpp")))))

(use-package diff-hl
  :hook ((prog-mode org-mode) . diff-hl-mode)
  :init
  (diff-hl-margin-mode)
  (diff-hl-show-hunk-mouse-mode)
  )

(use-package dirvish
  :bind (
          ("<DUMMY-i> d" . 'dirvish)
          ("C-=" . 'dirvish-side)
          )
  :bind (:map dirvish-mode-map
          ("/" . dirvish-narrow)
          ("<left>" . dired-up-directory)
          ("<right>" . dired-find-file)
          ("J" . dirvish-history-jump)
          ("M-b" . dirvish-history-go-backward)
          ("M-e" . dirvish-emerge-menu)
          ("M-f" . dirvish-history-go-forward)
          ("M-j" . dirvish-fd-jump)
          ("M-l" . dirvish-ls-switches-menu)
          ("M-m" . dirvish-mark-menu)
          ("M-s" . dirvish-setup-menu)
          ("M-t" . dirvish-layout-toggle)
          ("TAB" . dirvish-subtree-toggle)
          ("a" . dirvish-quick-access)
          ("f" . dirvish-file-info-menu)
          ("h" . dired-up-directory)
          ("j" . evil-next-visual-line)
          ("k" . evil-previous-visual-line)
          ("l" . dired-find-file)
          ("y" . dirvish-yank-menu)
          ("z" . dirvish-history-last)
          )
  :custom
  (delete-by-moving-to-trash t)
  (dired-listing-switches "-l --almost-all --human-readable --group-directories-first --no-group")
  (dirvish-attributes '(vc-state subtree-state nerd-icons collapse file-time file-size))
  (dirvish-quick-access-entries '(("h" "~/"              "Home")
                                   ("c" "~/.dotfiles/"    "Config")
                                   ("d" "~/Downloads/"    "Downloads")
                                   ("D" "~/Documents/"    "Documents")
                                   ("p" "~/Documents/GitHub/"  "Projects")
                                   ("/" "/"               "Root")))
  :init
  (dirvish-override-dired-mode)
  :config
  (dirvish-peek-mode)
  (dirvish-side-follow-mode)
  )

(use-package dockerfile-mode
  :mode "Dockerfile")

(use-package doom-themes
  :hook (server-after-make-frame . (lambda () (load-theme 'doom-city-lights t)))
  :config
  (load-theme 'doom-city-lights t)
  (doom-themes-treemacs-config)
  (doom-themes-org-config)
  (with-eval-after-load 'gnus
    (put 'gnus-group-news-low 'face-defface-spec '((t (:weight bold)))))
  )

(use-package eglot
  :bind (:map eglot-mode-map
          ("C-c ," . eglot-code-actions)
          ("M-(" . flymake-goto-next-error)
          )
  :hook ((python-mode python-ts-mode c-mode c-ts-mode c++-mode c++-ts-mode go-mode go-ts-mode tex-mode LaTeX-mode) . swarsel/eglot-ensure-and-format)
  :custom
  (eglot-autoshutdown t)
  (eglot-connect-timeout nil)
  (eglot-events-buffer-size 0)
  (eglot-send-changes-idle-time 3)
  (eglot-sync-connect nil)
  (eldoc-echo-area-prefer-doc-buffer t)
  (eldoc-echo-area-use-multiline-p nil)
  (flymake-no-changes-timeout 5)
  :init
  (defun swarsel/eglot-ensure-and-format ()
    "Ensure eglot is running and enable format-on-save for current buffer."
    (eglot-ensure)
    (add-hook 'before-save-hook #'eglot-format nil 'local))

  (defalias 'start-lsp-server #'eglot)

  :config
  (fset #'jsonrpc--log-event #'ignore))

(use-package eglot-booster
  :after (eglot)
  :config
  (eglot-booster-mode))

(use-package eldoc-box
  :after (eglot)
  :hook (eglot-managed-mode . eldoc-box-hover-at-point-mode))

(use-package elfeed
  :custom
  (elfeed-db-directory "~/.elfeed/db/")
  (elfeed-set-timeout 36000)
  (elfeed-use-curl t)
  :config
  (define-key elfeed-show-mode-map (kbd ";") #'visual-fill-column-mode)
  (define-key elfeed-show-mode-map (kbd "j") #'elfeed-goodies/split-show-next)
  (define-key elfeed-show-mode-map (kbd "k") #'elfeed-goodies/split-show-prev)
  (define-key elfeed-search-mode-map (kbd "j") #'next-line)
  (define-key elfeed-search-mode-map (kbd "k") #'previous-line)
  (define-key elfeed-show-mode-map (kbd "S-SPC") #'scroll-down-command)
  )

(use-package elfeed-goodies
  :after (elfeed)
  :config
  (elfeed-goodies/setup))

(use-package elfeed-protocol
  :after (elfeed)
  :custom
  (elfeed-protocol-enabled-protocols '(fever))
  (elfeed-protocol-fever-fetch-category-as-tag t)
  (elfeed-protocol-fever-update-unread-only t)
  :config
  (elfeed-protocol-enable)
  (let ((domain (getenv "SWARSEL_RSS_DOMAIN")))
    (setq elfeed-protocol-feeds
      `((,(concat "fever+https://Swarsel@" domain)
          :api-url ,(concat "https://" domain "/api/fever.php")
          :password-file "~/.emacs.d/.fever"))))
  )

(use-package embark
  :bind (
          ("C-." . embark-act)
          ("C-c c" . embark-collect)
          ("C-h B" . embark-bindings)
          ("M-." . embark-dwim)
          )
  :custom
  (embark-quit-after-action '((t . nil)))
  (prefix-help-command #'embark-prefix-help-command)
  :config
  (add-to-list 'display-buffer-alist
    '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
       nil
       (window-parameters (mode-line-format . none))))
  )

(use-package embark-consult
  :after (embark consult)
  :demand t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package envrc
  :hook (after-init . envrc-global-mode))

(use-package evil
  :init
  (defun swarsel/toggle-evil-state ()
    (interactive)
    (if (or (evil-emacs-state-p) (evil-insert-state-p))
      (evil-normal-state)
      (evil-emacs-state)))

  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-i-jump nil)
  (setq evil-want-Y-yank-to-eol t)
  (setq evil-shift-width 2)
  (setq evil-respect-visual-line-mode nil)
  (setq evil-split-window-below t)
  (setq evil-vsplit-window-right t)

  :config
  (evil-mode 1)

  (advice-add 'evil-insert :around #'suppress-messages)
  (advice-add 'evil-visual-char :around #'suppress-messages)

  (define-key evil-normal-state-map (kbd "j") 'evil-next-visual-line)
  (define-key evil-normal-state-map (kbd "<down>") 'evil-next-visual-line)
  (define-key evil-normal-state-map (kbd "k") 'evil-previous-visual-line)
  (define-key evil-normal-state-map (kbd "<up>") 'evil-previous-visual-line)

  (define-key evil-normal-state-map (kbd "C-z") nil)
  (define-key evil-insert-state-map (kbd "C-z") nil)
  (define-key evil-visual-state-map (kbd "C-z") nil)
  (define-key evil-motion-state-map (kbd "C-z") nil)
  (define-key evil-operator-state-map (kbd "C-z") nil)
  (define-key evil-replace-state-map (kbd "C-z") nil)
  (evil-set-undo-system 'undo-tree)

  (evil-set-initial-state 'messages-buffer-mode 'emacs)
  (evil-set-initial-state 'dashboard-mode 'emacs)
  (evil-set-initial-state 'dired-mode 'emacs)
  (evil-set-initial-state 'cfw:details-mode 'emacs)
  (evil-set-initial-state 'Custom-mode 'emacs)
  (evil-set-initial-state 'mu4e-headers-mode 'normal)
  (evil-set-initial-state 'python-inferior-mode 'normal)
  (evil-set-initial-state 'claude-code-vterm-mode 'emacs)
  (evil-set-initial-state 'vterm-mode 'emacs)
  (add-hook 'org-capture-mode-hook 'evil-insert-state)
  (add-to-list 'evil-buffer-regexps '("COMMIT_EDITMSG" . insert))
  )

(use-package evil-cleverparens)

(use-package evil-collection
  :after (evil)
  :config
  (evil-collection-init))

(use-package evil-mc
  :after (evil)
  :config
  (global-evil-mc-mode 1))

(use-package evil-nerd-commenter
  :bind (
          ("M-/" . evilnc-comment-or-uncomment-lines)
          ))

(use-package evil-numbers)

(use-package evil-snipe
  :after (evil)
  :demand t
  :config
  (evil-snipe-mode +1)
  (evil-snipe-override-mode +1)
  )

(use-package evil-surround
  :config
  (global-evil-surround-mode 1))

(use-package evil-textobj-tree-sitter
  :config
  (define-key evil-outer-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.outer"))
  (define-key evil-inner-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.inner"))
  (define-key evil-outer-text-objects-map "a" (evil-textobj-tree-sitter-get-textobj ("if_statement.outer" "conditional.outer" "loop.outer") '((python-mode . ((if_statement.outer) @if_statement.outer)) (python-ts-mode . ((if_statement.outer) @if_statement.outer)))))
  )

(use-package evil-visual-mark-mode
  :commands (evil-visual-mark-mode))

(use-package forge
  :after (magit)
  :init
  (setq forge-add-default-bindings nil))

(use-package general
  :init
  (defun swarsel/last-buffer () (interactive) (switch-to-buffer nil))

  (defun crux-get-positions-of-line-or-region ()
    "Return positions (beg . end) of the current line or region."
    (let (beg end)
      (if (and mark-active (> (point) (mark)))
        (exchange-point-and-mark))
      (setq beg (line-beginning-position))
      (if mark-active
        (exchange-point-and-mark))
      (setq end (line-end-position))
      (cons beg end)))

  (defun crux-duplicate-current-line-or-region (arg)
    "Duplicates the current line or region ARG times.
  If there's no region, the current line will be duplicated.  However, if
  there's a region, all lines that region covers will be duplicated."
    (interactive "p")
    (pcase-let* ((origin (point))
                  (`(,beg . ,end) (crux-get-positions-of-line-or-region))
                  (region (buffer-substring-no-properties beg end)))
      (dotimes (_i arg)
        (goto-char end)
        (newline)
        (insert region)
        (setq end (point)))
      (goto-char (+ origin (* (length region) arg) arg))))

  (defun crux-duplicate-and-comment-current-line-or-region (arg)
    "Duplicates and comments the current line or region ARG times.
If there's no region, the current line will be duplicated.  However, if
there's a region, all lines that region covers will be duplicated."
    (interactive "p")
    (pcase-let* ((origin (point))
                  (`(,beg . ,end) (crux-get-positions-of-line-or-region))
                  (region (buffer-substring-no-properties beg end)))
      (comment-or-uncomment-region beg end)
      (setq end (line-end-position))
      (dotimes (_ arg)
        (goto-char end)
        (newline)
        (insert region)
        (setq end (point)))
      (goto-char (+ origin (* (length region) arg) arg))))

  (eval-and-compile
    (require 'general)
    (general-create-definer swarsel/leader-keys
      :keymaps '(normal insert visual emacs)
      :prefix "SPC"
      :global-prefix "C-SPC"))

  :config
  (swarsel/leader-keys
    "mc" '((lambda () (interactive) (swarsel/open-calendar)) :which-key "calendar"))

  (swarsel/leader-keys
    "md" '(dirvish :which-key "dirvish"))

  (swarsel/leader-keys
    "mr" '(bjm/elfeed-load-db-and-open :which-key "elfeed"))

  (swarsel/leader-keys
    "eo" '(evil-jump-backward :which-key "cursor jump backwards")
    "eO" '(evil-jump-forward :which-key "cursor jump forwards")
    "te" '(swarsel/toggle-evil-state :which-key "emacs/evil")
    "tp" '(evil-cleverparens-mode :wk "cleverparens"))

  (swarsel/leader-keys
    "e"  '(:ignore e :which-key "evil")
    "t"  '(:ignore t :which-key "toggles")
    "tl" '(display-line-numbers-mode :which-key "line numbers")
    "to" '(olivetti-mode :wk "olivetti")
    "td" '(darkroom-tentative-mode :wk "darkroom")
    "tw" '((lambda () (interactive) (toggle-truncate-lines)) :which-key "line wrapping")
    "m"  '(:ignore m :which-key "modes/programs")
    "l"  '(:ignore l :which-key "links")
    "h"   '(:ignore h :which-key "help")
    "hy"  '(yas-describe-tables :which-key "yas tables")
    "hb"  '(embark-bindings :which-key "current key bindings")
    "h"   '(:ignore t :which-key "describe")
    "he"  'view-echo-area-messages
    "hf"  'describe-function
    "hF"  'describe-face
    "hl"  '(view-lossage :which-key "show command keypresses")
    "hL"  'find-library
    "hm"  'describe-mode
    "ho"  'describe-symbol
    "hk"  'describe-key
    "hK"  'describe-keymap
    "hp"  'describe-package
    "hv"  'describe-variable
    "hd"  'devdocs-lookup
    "w"   '(:ignore t :which-key "window")
    "wl"  'windmove-right
    "w <right>"  'windmove-right
    "wh"  'windmove-left
    "w <left>"  'windmove-left
    "wk"  'windmove-up
    "w <up>"  'windmove-up
    "wj"  'windmove-down
    "w <down>"  'windmove-down
    "wr"  'winner-redo
    "wd"  'delete-window
    "w="  'balance-windows-area
    "wD"  'kill-buffer-and-window
    "wu"  'winner-undo
    "wr"  'winner-redo
    "w/"  'evil-window-vsplit
    "w\\"  'evil-window-vsplit
    "w-"  'evil-window-split
    "wm"  '(delete-other-windows :wk "maximize")
    "<right>" 'up-list
    "<left>" 'down-list
    )

  (general-define-key
    "C-c d" 'crux-duplicate-current-line-or-region
    "C-c D" 'crux-duplicate-and-comment-current-line-or-region
    "<DUMMY-m>" 'swarsel/last-buffer
    "M-\\" 'indent-region
    "<Paste>" 'yank
    "<Cut>" 'kill-region
    "<Copy>" 'kill-ring-save
    "<undo>" 'evil-undo
    "<redo>" 'evil-redo
    )

  (swarsel/leader-keys
    "ts" '(hydra-text-scale/body :which-key "scale text"))

  (swarsel/leader-keys
    "mg" '((lambda () (interactive) (magit-list-repositories)) :which-key "magit-list-repos")
    "lr" '(swarsel/consult-magit-repos :which-key "List repos")
    "lg" '((lambda () (interactive) (magit-list-repositories)) :which-key "list git repos"))

  (general-define-key
    "M-r" 'swarsel/consult-magit-repos)

  (swarsel/leader-keys
    "mm" '((lambda () (interactive) (mu4e)) :which-key "mu4e"))

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
    "on" '(nixfmt-region :which-key "format nix-block")
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

  (swarsel/leader-keys
    "mp" '(popper-toggle :which-key "popper"))

  (swarsel/leader-keys
    "lp" '((lambda () (interactive) (projectile-switch-project)) :which-key "switch project"))
  )

(use-package git-timemachine
  :hook (git-time-machine-mode . evil-normalize-keymaps)
  :init
  (setq git-timemachine-show-minibuffer-details t))

(use-package groovy-mode)

(use-package hcl-mode
  :mode "\\.hcl\\'"
  :custom
  (hcl-indent-level 2))

(use-package helpful
  :bind (
          ("C-h C-." . helpful-at-point)
          ("C-h f" . helpful-callable)
          ("C-h k" . helpful-key)
          ("C-h v" . helpful-variable)
          )
  :custom
  (help-window-select nil))

(use-package hide-mode-line)

(use-package highlight-parentheses
  :config
  (setq highlight-parentheses-colors '("black" "white" "black" "black" "black" "black" "black"))
  (setq highlight-parentheses-background-colors '("magenta" "blue" "cyan" "green" "yellow" "orange" "red"))
  (global-highlight-parentheses-mode t)
  )

(use-package hunkle
  :after (magit)
  :config
  (hunkle-magit-setup))

(use-package hydra
  :config
  (defhydra hydra-text-scale (:timeout 4)
    "scale text"
    ("j" text-scale-increase "in")
    ("k" text-scale-decrease "out")
    ("f" nil "finished" :exit t))
  )

(use-package indent-bars
  :hook (prog-mode . indent-bars-mode))

(use-package jenkinsfile-mode
  :mode "Jenkinsfile")

(use-package jinx
  :bind (
          ("C-M-$" . jinx-languages)
          ("M-$" . jinx-correct)
          )
  :hook (text-mode . jinx-mode)
  :hook (prog-mode . jinx-mode)
  :hook (conf-mode . jinx-mode)
  :custom
  (jinx-languages "en_US"))

(use-package ligature
  :init
  (global-ligature-mode t)
  :config
  (ligature-set-ligatures 'prog-mode
    '("|||>" "<|||" "<==>" "<!--" "####" "~~>" "***" "||=" "||>"
       ":::" "::=" "=:=" "===" "==>" "=!=" "=>>" "=<<" "=/=" "!=="
       "!!." ">=>" ">>=" ">>>" ">>-" ">->" "->>" "-->" "---" "-<<"
       "<~~" "<~>" "<*>" "<||" "<|>" "<$>" "<==" "<=>" "<=<" "<->"
       "<--" "<-<" "<<=" "<<-" "<<<" "<+>" "</>" "###" "#_(" "..<"
       "..." "+++" "/==" "///" "_|_" "www" "&&" "^=" "~~" "~@" "~="
       "~>" "~-" "**" "*>" "*/" "||" "|}" "|]" "|=" "|>" "|-" "{|"
       "[|" "]#" "::" ":=" ":>" ":<" "$>" "==" "=>" "!=" "!!" ">:"
       ">=" ">>" ">-" "-~" "-|" "->" "--" "-<" "<~" "<*" "<|" "<:"
       "<$" "<=" "<>" "<-" "<<" "<+" "</" "#{" "#[" "#:" "#=" "#!"
       "##" "#(" "#?" "#_" "%%" ".=" ".." ".?" "+>" "++" "?:" "?="
       "?." "??" "/*" "/=" "/>" "//" "__" "~~" "(*" "*)" "\\\\"
       "://" ";;"))
  )

(use-package lsp-bridge)

(use-package lsp-mode
  :commands (lsp)
  :init
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

  :config
  (lsp-register-client
    (make-lsp-client :new-connection (lsp-stdio-connection "nixd")
      :major-modes '(nix-mode nix-ts-mode)
      :priority 0
      :server-id 'nixd))
  )

(use-package magit
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  :init
  (declare-function consult--read "consult")

  (defun swarsel/consult-magit-repos ()
    (interactive)
    (require 'magit)
    (let ((repos (magit-list-repos)))
      (unless repos
        (user-error "No repositories found in `magit-repository-directories'"))
      (let ((repo
              (if (or (fboundp 'consult--read)
                    (require 'consult nil t))
                (consult--read repos
                  :prompt "Magit repo: "
                  :require-match t
                  :history 'my/consult-magit-repos-history
                  :sort t)
                (completing-read "Magit repo: "
                  repos
                  nil
                  t
                  nil
                  'my/consult-magit-repos-history))))
        (when (and repo (> (length repo) 0))
          (magit-status repo)))))

  :config
  (advice-add 'magit-auto-revert-mode--init-kludge :around #'suppress-messages)

  (setq magit-repository-directories `((,swarsel-work-projects-directory  . 3)
                                        (,swarsel-private-projects-directory . 3)
                                        ("~/.dotfiles/" . 0)))
  ;; RET on a hunk/file always opens the editable worktree file at point,
  ;; never a read-only staged blob.
  (with-eval-after-load 'magit-diff
    (define-key magit-hunk-section-map [remap magit-visit-thing] #'magit-diff-visit-worktree-file)
    (define-key magit-file-section-map [remap magit-visit-thing] #'magit-diff-visit-worktree-file))
  )

(use-package marginalia
  :after (vertico)
  :bind (:map minibuffer-local-map
          ("M-A" . marginalia-cycle)
          )
  :init
  (marginalia-mode))

(use-package markdown-mode
  :bind (:map markdown-mode-map
          ("C-c C-e" . markdown-do)
          ("C-c C-x C-l" . org-latex-preview)
          ("C-c C-x C-u" . markdown-toggle-url-hiding)
          )
  :hook (markdown-mode . swarsel/markdown-mode-keys)
  :mode ("README\\.md\\'" . gfm-mode)
  :init
  (defun swarsel/markdown-mode-keys ()
    "Local markdown key customizations."
    (local-set-key (kbd "C-c C-x C-l") #'org-latex-preview)
    (local-set-key (kbd "C-c C-x C-u") #'markdown-toggle-url-hiding))

  (setq markdown-command "multimarkdown")
  )

(use-package mini-modeline
  :after (smart-mode-line)
  :custom
  (mini-modeline-display-gui-line nil)
  (mini-modeline-enhance-visual nil)
  (mini-modeline-l-format nil)
  (mini-modeline-r-format '("%e" mode-line-front-space mode-line-mule-info mode-line-client mode-line-modified mode-line-remote mode-line-frame-identification mode-line-buffer-identification " " mode-line-position " " mode-name evil-mode-line-tag))
  (mini-modeline-right-padding 5)
  (mini-modeline-truncate-p nil)
  :config
  (mini-modeline-mode t)
  (setq window-divider-default-places t
    window-divider-default-bottom-width 1
    window-divider-default-right-width 1)
  (window-divider-mode 1)
  )

(use-package mixed-pitch
  :hook (text-mode . mixed-pitch-mode)
  :custom
  (mixed-pitch-set-height nil)
  (mixed-pitch-variable-pitch-cursor nil))

(use-package mu4e
  :hook (mu4e-compose-mode . swarsel/mu4e-send-from-correct-address)
  :hook (mu4e-compose-post . swarsel/mu4e-restore-default)
  :init
  (defun swarsel/mu4e-switch-account ()
    (interactive)
    (let ((account (completing-read "Select account: " mu4e-user-mail-address-list)))
      (setq user-mail-address account)))

  (defun swarsel/mu4e-rfs--matching-address ()
    (cl-loop for to-data in (mu4e-message-field mu4e-compose-parent-message :to)
      for to-email = (pcase to-data
                       (`(_ . email) email)
                       (x (mu4e-contact-email x)))
      for to-name =  (pcase to-data
                       (`(_ . name) name)
                       (x (mu4e-contact-name x)))
      when (mu4e-user-mail-address-p to-email)
      return (list to-name to-email)))

  (defun swarsel/mu4e-send-from-correct-address ()
    (when mu4e-compose-parent-message
      (save-excursion
        (when-let ((dest (swarsel/mu4e-rfs--matching-address)))
          (cl-destructuring-bind (from-user from-addr) dest
            (setq user-mail-address from-addr)
            (when (and (boundp 'user-mail-address)
                    (stringp user-mail-address)
                    (string-equal user-mail-address (getenv "SWARSEL_MAIL_WORK")))
              (mml-secure-message-sign-smime))
            (message-position-on-field "From")
            (message-beginning-of-line)
            (delete-region (point) (line-end-position))
            (insert (format "%s <%s>" (or from-user user-full-name) from-addr)))))))

  (defun swarsel/mu4e-restore-default ()
    (setq user-mail-address (getenv "SWARSEL_MAIL4")
      user-full-name (getenv "SWARSEL_FULLNAME")))

  :config
  (advice-add 'mu4e--server-filter :around #'suppress-messages)

  (setq send-mail-function 'sendmail-send-it)
  (setq mu4e-change-filenames-when-moving t)
  (setq mu4e-mu-binary (executable-find "mu"))
  (setq mu4e-hide-index-messages t)

  (setq mu4e-search-skip-duplicates nil)

  (setq mu4e-update-interval 60)
  (setq mu4e-get-mail-command "mbsync -a")
  (setq mu4e-maildir "~/Mail")

  (setq mu4e-view-show-images t)
  (when (fboundp 'imagemagick-register-types)
    (imagemagick-register-types))

  (setq mu4e-drafts-folder "/Drafts")
  (setq mu4e-sent-folder   "/Sent Mail")
  (setq mu4e-refile-folder "/All Mail")
  (setq mu4e-trash-folder  "/Trash")

  (setq mu4e-maildir-shortcuts
    '((:maildir "/leon/Inbox"    :key ?1)
       (:maildir "/nautilus/Inbox" :key ?2)
       (:maildir "/mrswarsel/Inbox"     :key ?3)
       (:maildir "/work/Inbox"     :key ?4)
       (:maildir "/Sent Mail"     :key ?s)
       (:maildir "/Trash"     :key ?t)
       (:maildir "/Drafts"     :key ?d)
       (:maildir "/All Mail"     :key ?a)))

  (setq user-mail-address (getenv "SWARSEL_MAIL4")
    user-full-name (getenv "SWARSEL_FULLNAME"))

  (setq mu4e-user-mail-address-list
    (mapcar #'intern (split-string (or (getenv "SWARSEL_MAIL_ALL") "") "[ ,]+" t)))

  (setq mu4e--log-max-size 1000)

  (mu4e t)

  (let ((work (getenv "SWARSEL_MAIL_WORK")))
    (when (and work (not (string-empty-p work)))
      (setq swarsel-smime-cert-path "~/.Certificates/$SWARSEL_MAIL_WORK.pem")
      (setq swarsel-smime-cert-path (substitute-env-vars swarsel-smime-cert-path))
      (setq mml-secure-prefer-scheme 'smime)
      (setq mml-secure-smime-sign-with-sender t)
      (add-hook 'mu4e-compose-mode-hook
        (lambda ()
          (when (and (boundp 'user-mail-address)
                  (stringp user-mail-address)
                  (string-equal user-mail-address (getenv "SWARSEL_MAIL_WORK")))
            (mml-secure-message-sign-smime))))
      (setq smime-keys
        `((,(getenv "SWARSEL_MAIL_WORK")
            ,swarsel-smime-cert-path
            ("~/Certificates/harica-root.pem"
              "~/Certificates/harica-intermediate.pem"))))
      ))

  (setq mu4e-bookmarks
    `((:name "Unread messages" :query "flag:unread AND NOT flag:trashed" :key 117)
       (:name "Undeleted messages" :query "NOT flag:trashed" :key 103)
       (:name "Today's messages" :query "date:today..now" :key 116)
       (:name "Today's undeleted messages" :query "date:today..now AND NOT flag:trashed" :key 100)
       (:name "Last 7 days" :query "date:7d..now" :hide-unread t :key 119)
       (:name "Messages with images" :query "mime:image/*" :key 112))
    )
  )

(use-package mu4e-alert
  :config
  (mu4e-alert-enable-notifications)
  (mu4e-alert-set-default-style 'libnotify)
  (setq mu4e-alert-interesting-mail-query
    (concat "(maildir:/leon/Inbox AND date:today..now"
      " OR maildir:/work/Inbox AND date:today..now)"
      " AND flag:unread"))
  (alert-add-rule
    :category "mu4e-alert"
    :predicate (lambda (_) (string-match-p "^mu4e-" (symbol-name major-mode)))
    :continue t)

  (add-hook 'after-init-hook #'mu4e-alert-enable-notifications)
  )

(use-package nerd-icons)

(use-package nerd-icons-completion
  :after (marginalia nerd-icons)
  :hook (marginalia-mode . nerd-icons-completion-marginalia-setup)
  :init
  (nerd-icons-completion-mode))

(use-package nerd-icons-corfu
  :after (corfu)
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter)
  (setq nerd-icons-corfu-mapping
    '((array :style "cod" :icon "symbol_array" :face font-lock-type-face)
       (boolean :style "cod" :icon "symbol_boolean" :face font-lock-builtin-face)
       (t :style "cod" :icon "code" :face font-lock-warning-face)))
  )

(use-package nix-mode
  :after (lsp-mode)
  :hook (nix-mode . lsp-deferred)
  :custom
  (lsp-disabled-clients '((nix-mode . nix-nil)))
  :config
  (setq lsp-nix-nixd-server-path "nixd"
    lsp-nix-nixd-formatting-command [ "nixfmt" ]
    lsp-nix-nixd-nixpkgs-expr "import (builtins.getFlake \"/home/swarsel/.dotfiles\").inputs.nixpkgs { }"
    lsp-nix-nixd-nixos-options-expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").nixosConfigurations.pyramid.options"
    lsp-nix-nixd-home-manager-options-expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").nixosConfigurations.pyramid.options.home-manager.users.type.getSubOptions []"
    )
  )

(use-package nix-ts-mode
  :after (lsp-mode)
  :hook (nix-ts-mode . lsp-deferred)
  :mode "\\.nix\\'"
  :mode "\\.nix\\.enc\\'"
  :custom
  (lsp-disabled-clients '((nix-ts-mode . nix-nil)))
  :config
  (setq lsp-nix-nixd-server-path "nixd"
    lsp-nix-nixd-formatting-command [ "nixfmt" ]
    lsp-nix-nixd-nixpkgs-expr "import (builtins.getFlake \"/home/swarsel/.dotfiles\").inputs.nixpkgs { }"
    lsp-nix-nixd-nixos-options-expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").nixosConfigurations.pyramid.options"
    lsp-nix-nixd-home-manager-options-expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").nixosConfigurations.pyramid.options.home-manager.users.type.getSubOptions []"
    )
  )

(use-package nixfmt)

(use-package no-littering
  :config
  (setq custom-file (make-temp-file "emacs-custom-"))
  (load custom-file t)
  )

(use-package orderless
  :config
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
  )

(use-package org
  :bind (
          ("C-<tab>" . org-fold-outer)
          ("C-c s" . org-store-link)
          )
  :hook (org-mode . swarsel/org-mode-setup)
  :custom
  (org-confirm-babel-evaluate nil)
  (org-export-with-broken-links 'mark)
  (org-fold-core-style 'overlays)
  (org-html-htmlize-output-type nil)
  (org-src-fontify-natively t)
  (org-src-preserve-indentation nil)
  :init
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
      (shell-command "find . -name '*.nix' -exec nixfmt {} + > /dev/null")))

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

  :config
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

  (advice-add 'org-babel-tangle-single-block :around #'swarsel/org-babel-tangle-single-block-advice)
  (advice-add 'org-babel-tangle :around #'swarsel/org-babel-tangle-timing-advice)

  (require 'org-tempo)
  (add-to-list 'org-structure-template-alist '("sh" . "src shell"))
  (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '("py" . "src python :results output"))
  (add-to-list 'org-structure-template-alist '("nix" . "src nix-ts :tangle"))
  (add-to-list 'org-structure-template-alist '("ne" . "bash :exports both"))
  )

(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :init
  (setq org-appear-autolinks t)
  (setq org-appear-autokeywords t)
  (setq org-appear-autoentities t)
  (setq org-appear-autosubmarkers t)
  )

(use-package org-caldav
  :init
  (setq swarsel-caldav-synced 0)

  :config
  (setq org-icalendar-alarm-time 1)
  (setq org-icalendar-include-todo t)
  (setq org-icalendar-use-deadline '(event-if-todo event-if-not-todo todo-due))
  (setq org-icalendar-use-scheduled '(todo-start event-if-todo event-if-not-todo))
  )

(use-package org-fragtog
  :hook (org-mode . org-fragtog-mode)
  :hook (markdown-mode . org-fragtog-mode))

(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :config
  (setq org-modern-block-name
    '((t . t)
       ("src" "»" "∥")))
  )

(use-package org-present
  :bind (:map org-present-mode-keymap
          ("<left>" . swarsel/org-present-prev)
          ("<right>" . swarsel/org-present-next)
          ("<​down>" . 'ignore)
          ("<​up>" . 'ignore)
          ("q" . org-present-quit)
          )
  :hook (org-present-mode . swarsel/org-present-start)
  :hook (org-present-mode-quit . swarsel/org-present-end)
  :init
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

  :config
  (add-hook 'org-present-after-navigate-functions #'swarsel/org-present-slide)
  (setq org-present-startup-folded t)
  )

(use-package pinentry
  :config
  (pinentry-start)
  (setq epg-pinentry-mode 'loopback)
  )

(use-package popper
  :bind (
          ("M-[" . popper-toggle)
          )
  :init
  (setq popper-reference-buffers
    '("\\*Messages\\*"
       ("\\*Warnings\\*" . hide)
       "Output\\*$"
       "\\*Async Shell Command\\*"
       "\\*Async-native-compile-log\\*"
       help-mode
       helpful-mode
       "*Occur*"
       "*scratch*"
       "*julia*"
       "*Python*"
       "*rustic-compilation*"
       "*cargo-run*"
       (compilation-mode . hide)))
  (popper-mode +1)
  (popper-echo-mode +1)
  )

(use-package projectile
  :bind-keymap (
                 ("C-c p" . projectile-command-map)
                 )
  :diminish (projectile-mode)
  :custom
  (projectile-completion-system 'auto)
  :init
  (when (file-directory-p swarsel-work-projects-directory)
    (when (file-directory-p swarsel-private-projects-directory)
      (setq projectile-project-search-path (list swarsel-work-projects-directory swarsel-private-projects-directory))))
  (setq projectile-switch-project-action #'magit-status)

  :config
  (projectile-mode))

(use-package pulsar
  :custom
  (pulsar-face 'pulsar-green)
  (pulsar-highlight-face 'pulsar-cyan)
  (pulsar-pulse t)
  :config
  (pulsar-global-mode 1)
  (with-eval-after-load 'consult
    (add-hook 'consult-after-jump-hook #'pulsar-recenter-top)
    (add-hook 'consult-after-jump-hook #'pulsar-reveal-entry))
  )

(use-package python
  :custom
  (python-indent-guess-indent-offset-verbose nil))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package rainbow-mode
  :hook ((css-mode css-ts-mode web-mode html-mode html-ts-mode) . rainbow-mode))

(use-package recentf
  :config
  (add-to-list 'recentf-exclude "\\Archive\\.org\\'")
  (add-to-list 'recentf-exclude "\\Tasks\\.org\\'")
  )

(use-package repeat
  :custom
  (repeat-exit-timeout 3)
  :init
  (repeat-mode 1))

(use-package rg)

(use-package savehist
  :init
  (savehist-mode 1))

(use-package saveplace
  :init
  (save-place-mode 1))

(use-package shackle
  :config
  (setq shackle-rules '(("*Messages*" :select t :popup t :align right :size 0.3)
                         ("*Warnings*" :ignore t :popup t :align right :size 0.3)
                         ("*Occur*" :select t :popup t :align below :size 0.2)
                         ("*scratch*" :select t :popup t :align below :size 0.2)
                         ("*Python*" :select t :popup t :align below :size 0.2)
                         ("*rustic-compilation*" :select t :popup t :align below :size 0.4)
                         ("*cargo-run*" :select t :popup t :align below :size 0.2)
                         ("*tex-shell*" :ignore t :popup t :align below :size 0.2)
                         (helpful-mode :select t :popup t :align right :size 0.35)
                         (help-mode :select t :popup t :align right :size 0.4)))
  (shackle-mode 1)
  )

(use-package shfmt
  :custom
  (shfmt-arguments '("-i" "4" "-s" "-sr"))
  (shfmt-command "shfmt"))

(use-package sideline-flymake
  :hook (flymake-mode . sideline-mode)
  :init
  (setq sideline-flymake-display-mode 'point)
  (setq sideline-backends-right '(sideline-flymake))
  )

(use-package smart-mode-line
  :config
  (sml/setup)
  (add-to-list 'sml/replacer-regexp-list '("^~/Documents/Work/" ":WK:"))
  (add-to-list 'sml/replacer-regexp-list '("^~/Documents/Private/" ":PR:"))
  (add-to-list 'sml/replacer-regexp-list '("^~/.dotfiles/" ":D:") t)
  )

(use-package solaire-mode
  :custom
  (solaire-global-mode +1))

(use-package terraform-mode
  :hook (terraform-mode . outline-minor-mode)
  :mode "\\.tf\\'"
  :custom
  (terraform-format-on-save t)
  (terraform-indent-level 2))

(use-package tramp
  :init
  (setq vc-ignore-dir-regexp
    (format "\\(%s\\)\\|\\(%s\\)"
      vc-ignore-dir-regexp
      tramp-file-name-regexp))
  (setq tramp-default-method "ssh")
  (setq tramp-auto-save-directory
    (expand-file-name "tramp-auto-save" user-emacs-directory))
  (setq tramp-persistency-file-name
    (expand-file-name "tramp-connection-history" user-emacs-directory))
  (setq password-cache-expiry nil)
  (setq tramp-use-ssh-controlmaster-options nil)
  (setq remote-file-name-inhibit-cache nil)

  :config
  (customize-set-variable 'tramp-ssh-controlmaster-options
    (concat
      "-o ControlPath=/tmp/ssh-tramp-%%r@%%h:%%p "
      "-o ControlMaster=auto -o ControlPersist=yes"))
  )

(use-package treesit-fold
  :config
  (global-treesit-fold-mode 1))

(use-package ultra-scroll
  :custom
  (ultra-scroll-hide-functions '(global-hl-line-mode diff-hl-mode indent-bars-mode global-highlight-parentheses-mode rainbow-delimiters-mode))
  :init
  (setq scroll-conservatively 101
    scroll-margin 0)

  :config
  (ultra-scroll-mode 1))

(use-package undo-tree
  :bind (:map undo-tree-visualizer-mode-map
          ("h" . undo-tree-visualize-switch-branch-left)
          ("j" . undo-tree-visualize-redo)
          ("k" . undo-tree-visualize-undo)
          ("l" . undo-tree-visualize-switch-branch-left)
          )
  :init
  (global-undo-tree-mode)
  :config
  (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))

  (defun swarsel/clear-undo-tree ()
    (interactive)
    (setq buffer-undo-tree nil))

  (define-advice undo-list-transfer-to-tree (:around (orig-fun &rest args) ignore-gc)
    (cl-letf (((symbol-function 'garbage-collect) #'ignore))
      (apply orig-fun args)))
  )

(use-package vertico
  :custom
  (vertico-count 10)
  (vertico-cycle t)
  (vertico-resize t)
  (vertico-scroll-margin 0)
  :init
  (vertico-mode)
  (vertico-mouse-mode)
  )

(use-package vertico-directory
  :after (vertico)
  :bind (:map vertico-map
          ("C-DEL" . vertico-directory-delete-word)
          ("DEL" . vertico-directory-delete-char)
          ("RET" . vertico-directory-enter)
          )
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package visual-fill-column
  :hook (org-mode . swarsel/org-mode-visual-fill))

(use-package vterm
  :custom
  (vterm-tramp-shells '(("ssh" "'sh'"))))

(use-package wgrep
  :custom
  (wgrep-auto-save-buffer t))

(use-package which-key
  :diminish (which-key-mode)
  :custom
  (which-key-idle-delay 0.300000)
  :init
  (which-key-mode))


(provide 'hm-init)
;; hm-init.el ends here
