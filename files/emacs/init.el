(defun swarsel/toggle-evil-state ()
  (interactive)
  (if (or (evil-emacs-state-p) (evil-insert-state-p))
      (evil-normal-state)
    (evil-emacs-state)))

(defun swarsel/last-buffer () (interactive) (switch-to-buffer nil))

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
          (message-position-on-field "From")
          (message-beginning-of-line)
          (delete-region (point) (line-end-position))
          (insert (format "%s <%s>" (or from-user user-full-name) from-addr)))))))

(defun swarsel/mu4e-restore-default ()
  (setq user-mail-address (getenv "SWARSEL_SWARSEL_MAIL")
        user-full-name (getenv "SWARSEL_FULLNAME")))

(defun swarsel/with-buffer-name-prompt-and-make-subdirs ()
  (let ((parent-directory (file-name-directory buffer-file-name)))
    (when (and (not (file-exists-p parent-directory))
               (y-or-n-p (format "Directory `%s' does not exist! Create it? " parent-directory)))
      (make-directory parent-directory t))))

(add-to-list 'find-file-not-found-functions #'swarsel/with-buffer-name-prompt-and-make-subdirs)

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

(defun suppress-messages (old-fun &rest args)
  (cl-flet ((silence (&rest args1) (ignore)))
    (advice-add 'message :around #'silence)
    (unwind-protect
        (apply old-fun args)
      (advice-remove 'message #'silence))))

(advice-add 'pixel-scroll-precision :around #'suppress-messages)
(advice-add 'mu4e--server-filter :around #'suppress-messages)
(advice-add 'org-unlogged-message :around #'suppress-messages)
(advice-add 'magit-auto-revert-mode--init-kludge  :around #'suppress-messages)
(advice-add 'push-mark  :around #'suppress-messages)
(advice-add 'evil-insert  :around #'suppress-messages)
(advice-add 'evil-visual-char  :around #'suppress-messages)

;; to reenable
;; (advice-remove 'timer-event-handler #'suppress-messages)

(defun who-called-me? (old-fun format &rest args)
  (let ((trace nil) (n 1) (frame nil))
    (while (setf frame (backtrace-frame n))
      (setf n     (1+ n)
            trace (cons (cadr frame) trace)) )
    (apply old-fun (concat "<<%S>>\n" format) (cons trace args))))

;; enable to get message backtrace, the first function shown in backtrace calls the other functions
;; (advice-add 'message :around #'who-called-me?)

;; disable to stop receiving backtrace
(advice-remove 'message #'who-called-me?)

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
    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      ;; (org-html-export-to-html)
      (org-babel-tangle)
      (swarsel/run-formatting)
      )))

(setq org-html-htmlize-output-type nil)

;; (add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'swarsel/org-babel-tangle-config)))

(defun org-fold-outer ()
  (interactive)
  (org-beginning-of-line)
  (if (string-match "^*+" (thing-at-point 'line t))
      (outline-up-heading 1))
  (outline-hide-subtree)
  )

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

(defun swarsel/minibuffer-setup-hook ()
  (setq gc-cons-threshold most-positive-fixnum))

(defun swarsel/minibuffer-exit-hook ()
  (setq gc-cons-threshold (* 32 1024 1024)))

(add-hook 'minibuffer-setup-hook #'swarsel/minibuffer-setup-hook)
(add-hook 'minibuffer-exit-hook #'swarsel/minibuffer-exit-hook)

;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;; Set up general keybindings
(use-package general
  :config
  (general-create-definer swarsel/leader-keys
    :keymaps '(normal insert visual emacs)
    :prefix "SPC"
    :global-prefix "C-SPC")

  (swarsel/leader-keys
    "e"  '(:ignore e :which-key "evil")
    "eo" '(evil-jump-backward :which-key "cursor jump backwards")
    "eO" '(evil-jump-forward :which-key "cursor jump forwards")
    "t"  '(:ignore t :which-key "toggles")
    "ts" '(hydra-text-scale/body :which-key "scale text")
    "te" '(swarsel/toggle-evil-state :which-key "emacs/evil")
    "tl" '(display-line-numbers-mode :which-key "line numbers")
    "tp" '(evil-cleverparens-mode :wk "cleverparens")
    "to" '(olivetti-mode :wk "olivetti")
    "td" '(darkroom-tentative-mode :wk "darkroom")
    "tw" '((lambda () (interactive) (toggle-truncate-lines)) :which-key "line wrapping")
    "m"  '(:ignore m :which-key "modes/programs")
    "mm" '((lambda () (interactive) (mu4e)) :which-key "mu4e")
    "mg" '((lambda () (interactive) (magit-list-repositories)) :which-key "magit-list-repos")
    "mc" '((lambda () (interactive) (swarsel/open-calendar)) :which-key "calendar")
    "mp" '(popper-toggle :which-key "popper")
    "md" '(dirvish :which-key "dirvish")
    "mr" '(bjm/elfeed-load-db-and-open :which-key "elfeed")
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
    "l"  '(:ignore l :which-key "links")
    "lc" '((lambda () (interactive) (progn (find-file swarsel-swarsel-org-filepath) (org-overview) )) :which-key "SwarselSystems.org")
    "le" '((lambda () (interactive) (progn (find-file swarsel-swarsel-org-filepath) (goto-char (org-find-exact-headline-in-buffer "Emacs") ) (org-overview) (org-cycle) )) :which-key "Emacs.org")
    "ln" '((lambda () (interactive) (progn (find-file swarsel-swarsel-org-filepath) (goto-char (org-find-exact-headline-in-buffer "System") ) (org-overview) (org-cycle))) :which-key "Nixos.org")
    "lp" '((lambda () (interactive) (projectile-switch-project)) :which-key "switch project")
    "lg" '((lambda () (interactive) (magit-list-repositories)) :which-key "list git repos")
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
    ))

;; General often used hotkeys
(general-define-key
 "C-M-a" (lambda () (interactive) (org-capture nil "a")) ; make new anki card
 "C-c d" 'crux-duplicate-current-line-or-region
 "C-c D" 'crux-duplicate-and-comment-current-line-or-region
 "<DUMMY-m>" 'swarsel/last-buffer
 "M-\\" 'indent-region
 "<Paste>" 'yank
 "<Cut>" 'kill-region
 "<Copy>" 'kill-ring-save
 "<undo>" 'evil-undo
 "<redo>" 'evil-redo
 "C-S-c C-S-c" 'mc/edit-lines
 "C->" 'mc/mark-next-like-this
 "C-<" 'mc/mark-previous-like-this
 "C-c C-<" 'mc/mark-all-like-this
 )

;; set Nextcloud directory for journals etc.
(setq
 swarsel-emacs-directory "~/.emacs.d"
 swarsel-dotfiles-directory "~/.dotfiles"
 swarsel-swarsel-org-filepath (expand-file-name "SwarselSystems.org" swarsel-dotfiles-directory)
 swarsel-tasks-org-file "Tasks.org"
 swarsel-archive-org-file "Archive.org"
 swarsel-work-projects-directory "~/Documents/Work"
 swarsel-private-projects-directory "~/Documents/Private"
 )

;; Change the user-emacs-directory to keep unwanted things out of ~/.emacs.d
(setq user-emacs-directory (expand-file-name "~/.cache/emacs/")
      url-history-file (expand-file-name "url/history" user-emacs-directory))

;; Use no-littering to automatically set common paths to the new user-emacs-directory
(use-package no-littering)
(setq custom-file (make-temp-file "emacs-custom-"))
(load custom-file t)

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

(setq backup-by-copying t    ; Don't delink hardlinks
      delete-old-versions t  ; Clean up the backups
      version-control t      ; Use version numbers on backups,
      kept-new-versions 5    ; keep some new versions
      kept-old-versions 2)   ; and some old ones, too

;; use UTF-8 everywhere
(set-language-environment "UTF-8")
(profiler-start 'cpu)
;; set default font size
(defvar swarsel/default-font-size 130)
(setq swarsel-standard-font "FiraCode Nerd Font Mono"
      swarsel-alt-font "FiraCode Nerd Font Mono")

;; (defalias 'yes-or-no-p 'y-or-n-p)
;;(setq-default show-trailing-whitespace t)
(add-hook 'before-save-hook 'delete-trailing-whitespace)
(global-hl-line-mode 1)
;; (setq redisplay-dont-pause t) ;; obsolete
(setq blink-cursor-mode nil) ;; blink-cursor is an unexpected source of slowdown
(global-subword-mode 1) ; Iterate through CamelCase words
(setq blink-matching-paren nil) ;; this makes the cursor jump around annoyingly
(delete-selection-mode 1)
(setq vc-follow-symlinks t)
(setq require-final-newline t)
(winner-mode 1)
(setq load-prefer-newer t)
(setq-default bidi-paragraph-direction 'left-to-right
              bidi-display-reordering 'left-to-right
              bidi-inhibit-bpa t)
(global-so-long-mode)
(setq process-adaptive-read-buffering nil) ;; not sure if this is a good idea
(setq fast-but-imprecise-scrolling t
      redisplay-skip-fontification-on-input t
      inhibit-compacting-font-caches t)
(setq idle-update-delay 1.0
      which-func-update-delay 1.0)
(setq undo-limit 80000000
      evil-want-fine-undo t
      auto-save-default t
      password-cache-expiry nil
      )
(setq browse-url-browser-function 'browse-url-firefox)
(setenv "DISPLAY" ":0")
;; disable a keybind that does more harm than good
(global-set-key [remap suspend-frame]
                (lambda ()
                  (interactive)
                  (message "This keybinding is disabled (was 'suspend-frame')")))

(setq visible-bell nil)
(setq initial-major-mode 'fundamental-mode
      initial-scratch-message nil)

(add-hook 'prog-mode-hook 'display-line-numbers-mode)
;; (add-hook 'text-mode-hook 'display-line-numbers-mode)
;; (global-visual-line-mode 1)

(setq custom-safe-themes t)

(setq byte-compile-warnings '(not free-vars unresolved noruntime lexical make-local))
;; Make native compilation silent and prune its cache.
(when (native-comp-available-p)
  (setq native-comp-async-report-warnings-errors 'silent) ; Emacs 28 with native compilation
  (setq native-compile-prune-cache t)) ; Emacs 29

(setq garbage-collection-messages nil)
(defmacro k-time (&rest body)
  "Measure and return the time it takes evaluating BODY."
  `(let ((time (current-time)))
     ,@body
     (float-time (time-since time))))


;; When idle for 15sec run the GC no matter what.
(defvar k-gc-timer
  (run-with-idle-timer 15 t
                       (lambda ()
                         ;; (message "Garbage Collector has run for %.06fsec"
                         (k-time (garbage-collect)))))
;; )

(setq-default indent-tabs-mode nil
              tab-width 2)

(setq tab-always-indent 'complete)
(setq python-indent-guess-indent-offset-verbose nil)

(use-package highlight-indent-guides
  :hook (prog-mode . highlight-indent-guides-mode)
  :init
  (setq highlight-indent-guides-method 'column)
  (setq highlight-indent-guides-responsive 'top)
  )

(with-eval-after-load 'highlight-indent-guides
  (set-face-attribute 'highlight-indent-guides-even-face nil :background "gray10")
  (set-face-attribute 'highlight-indent-guides-odd-face nil :background "gray20")
  (set-face-attribute 'highlight-indent-guides-stack-even-face nil :background "gray40")
  (set-face-attribute 'highlight-indent-guides-stack-odd-face nil :background "gray50"))

;; (use-package aggressive-indent)
;; (global-aggressive-indent-mode 1)

(setq mouse-wheel-scroll-amount
      '(1
        ((shift) . 5)
        ((meta) . 0.5)
        ((control) . text-scale))
      mouse-drag-copy-region nil
      make-pointer-invisible t
      mouse-wheel-progressive-speed t
      mouse-wheel-follow-mouse t)

(setq-default scroll-preserve-screen-position t
              scroll-conservatively 1
              scroll-margin 0
              next-screen-context-lines 0)

(pixel-scroll-precision-mode 1)

;; Emulate vim in emacs
(use-package evil
  :init
  (setq evil-want-integration t) ; loads evil
  (setq evil-want-keybinding nil) ; loads "helpful bindings" for other modes
  (setq evil-want-C-u-scroll t) ; scrolling using C-u
  (setq evil-want-C-i-jump nil) ; jumping with C-i
  (setq evil-want-Y-yank-to-eol t) ; give Y some utility
  (setq evil-shift-width 2) ; uniform indent
  (setq evil-respect-visual-line-mode nil) ; i am torn on this one
  (setq evil-split-window-below t)
  (setq evil-vsplit-window-right t)
  :config
  (evil-mode 1)

  ;; make normal mode respect wrapped lines
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
  (define-key global-map (kbd "C-z") nil)
  (evil-set-undo-system 'undo-tree)

  ;; Don't use evil-mode in these contexts, or use it in a specific mode
  (evil-set-initial-state 'messages-buffer-mode 'emacs)
  (evil-set-initial-state 'dashboard-mode 'emacs)
  (evil-set-initial-state 'dired-mode 'emacs)
  (evil-set-initial-state 'cfw:details-mode 'emacs)
  (evil-set-initial-state 'Custom-mode 'emacs) ; god knows why this mode is in uppercase
  (evil-set-initial-state 'mu4e-headers-mode 'normal)
  (evil-set-initial-state 'python-inferior-mode 'normal)
  (add-hook 'org-capture-mode-hook 'evil-insert-state)
  (add-to-list 'evil-buffer-regexps '("COMMIT_EDITMSG" . insert)))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init)
  (setq forge-add-default-bindings nil))

;; enables 2-char inline search
(use-package evil-snipe
  :after evil
  :demand
  :config
  (evil-snipe-mode +1)
  ;; replace 1-char searches (f&t) with this better UI
  (evil-snipe-override-mode +1))

;; for parentheses-heavy languades modify evil commands to keep balance of parantheses
(use-package evil-cleverparens)

;; enables surrounding text with S
(use-package evil-surround
  :config
  (global-evil-surround-mode 1))

(use-package evil-visual-mark-mode
  :config (evil-visual-mark-mode))

(use-package evil-textobj-tree-sitter)
;; bind `function.outer`(entire function block) to `f` for use in things like `vaf`, `yaf`
(define-key evil-outer-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.outer"))
;; bind `function.inner`(function block without name and args) to `f` for use in things like `vif`, `yif`
(define-key evil-inner-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.inner"))

;; You can also bind multiple items and we will match the first one we can find
(define-key evil-outer-text-objects-map "a" (evil-textobj-tree-sitter-get-textobj ("if_statement.outer" "conditional.outer" "loop.outer") '((python-mode . ((if_statement.outer) @if_statement.outer)) (python-ts-mode . ((if_statement.outer) @if_statement.outer)))))

(use-package evil-numbers)

;; set the NixOS wordlist by hand
(setq ispell-alternate-dictionary (getenv "WORDLIST"))

(dolist (face '(default fixed-pitch))
  (set-face-attribute face nil
                      :font "FiraCode Nerd Font Mono"))
(add-to-list 'default-frame-alist '(font . "FiraCode Nerd Font Mono"))

(set-face-attribute 'default nil :height 100)
(set-face-attribute 'fixed-pitch nil :height 1.0)

(set-face-attribute 'variable-pitch nil
                    :family "IBM Plex Sans"
                    :weight 'regular
                    :height 1.06)

(use-package solaire-mode
  :custom
  (solaire-global-mode +1))

(use-package doom-themes
  :hook
  (server-after-make-frame . (lambda () (load-theme
                                         'doom-city-lights t)))
  :config
  (load-theme 'doom-city-lights t)
  (doom-themes-treemacs-config)
  (doom-themes-org-config))

(use-package nerd-icons)

(use-package mixed-pitch
  :custom
  (mixed-pitch-set-height nil)
  (mixed-pitch-variable-pitch-cursor nil)
  :hook
  (text-mode . mixed-pitch-mode))

(use-package doom-modeline
  :init
  ;; (doom-modeline-mode)
  ;; (column-number-mode)
  :custom
  ((doom-modeline-height 22)
   (doom-modeline-indent-info nil)
   (doom-modeline-buffer-encoding nil)))

(use-package mini-modeline
  :after smart-mode-line
  :config
  (mini-modeline-mode t)
  (setq mini-modeline-display-gui-line nil)
  (setq mini-modeline-enhance-visual nil)
  (setq mini-modeline-truncate-p nil)
  (setq mini-modeline-l-format nil)
  (setq mini-modeline-right-padding 5)
  (setq window-divider-mode t)
  (setq window-divider-default-places t)
  (setq window-divider-default-bottom-width 1)
  (setq window-divider-default-right-width 1)
  (setq mini-modeline-r-format '("%e" mode-line-front-space mode-line-mule-info mode-line-client
                                 mode-line-modified mode-line-remote mode-line-frame-identification
                                 mode-line-buffer-identification " " mode-line-position " " mode-name evil-mode-line-tag ))
  )

(use-package smart-mode-line
  :config
  (sml/setup)
  (add-to-list 'sml/replacer-regexp-list '("^~/Documents/Work/" ":WK:"))
  (add-to-list 'sml/replacer-regexp-list '("^~/Documents/Private/" ":PR:"))
  (add-to-list 'sml/replacer-regexp-list '("^~/.dotfiles/" ":D:") t)
  )

(setq read-buffer-completion-ignore-case t
      read-file-name-completion-ignore-case t
      completion-ignore-case t)

(use-package vertico
  :custom
  (vertico-scroll-margin 0)
  (vertico-count 10)
  (vertico-resize t)
  (vertico-cycle t)
  :init
  (vertico-mode)
  (vertico-mouse-mode))

(use-package vertico-directory
  :ensure nil
  :after vertico
  :bind (:map vertico-map
              ("RET" . vertico-directory-enter)
              ("C-DEL" . vertico-directory-delete-word)
              ("DEL" . vertico-directory-delete-char))
  ;; Tidy shadowed file names
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

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
        orderless-matching-styles '(orderless-literal orderless-regexp)))

(use-package consult
  :config
  (setq consult-fontify-max-size 1024)
  :bind
  (("C-x b" . consult-buffer)
   ("C-c <C-m>" . consult-global-mark)
   ("C-c C-a" . consult-org-agenda)
   ("C-x O" . consult-org-heading)
   ("C-M-j" . consult-buffer)
   ("C-s" . consult-line)
   ("M-g M-g" . consult-goto-line)
   ("M-g i" . consult-imenu)
   ("M-s M-s" . consult-line-multi)
   :map minibuffer-local-map
   ("C-j" . next-line)
   ("C-k" . previous-line)))

(use-package embark
  :bind
  (("C-." . embark-act)
   ("M-." . embark-dwim)
   ("C-h B" . embark-bindings)
   ("C-c c" . embark-collect))
  :custom
  (prefix-help-command #'embark-prefix-help-command)
  (embark-quit-after-action '((t . nil)))
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package embark-consult
  :after (embark consult)
  :demand t ; only necessary if you have the hook below
  ;; if you want to have consult previews as you move around an
  ;; auto-updating embark collect buffer
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package marginalia
  :after vertico
  :init
  (marginalia-mode)
  (setq marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil)))

(use-package nerd-icons-completion
  :after (marginalia nerd-icons)
  :hook (marginalia-mode . nerd-icons-completion-marginalia-setup)
  :init
  (nerd-icons-completion-mode))

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.3))

(use-package helpful
  :bind
  (("C-h f" . helpful-callable)
   ("C-h v" . helpful-variable)
   ("C-h k" . helpful-key)
   ("C-h C-." . helpful-at-point))
  :config
  (setq help-window-select nil))

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
                            "://" ";;")))

(use-package popper
  :bind (("M-["   . popper-toggle))
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
          ;; ("*tex-shell*" . hide)
          (compilation-mode . hide)))
  (popper-mode +1)
  (popper-echo-mode +1))

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
  (shackle-mode 1))

(setq-default indicate-buffer-boundaries t)

;; (setq auth-sources '( "~/.emacs.d/.caldav" "~/.emacs.d/.authinfo.gpg")
;; auth-source-cache-expiry nil) ; default is 2h

(setq auth-sources '( "~/.emacs.d/.authinfo")
      auth-source-cache-expiry nil)

(use-package org
  ;;:diminish (org-indent-mode)
  :hook (org-mode . swarsel/org-mode-setup)
  ;; :mode "\\.nix\\'"
  :bind
  (("C-<tab>" . org-fold-outer)
   ("C-c s" . org-store-link))
  :config
  (setq org-ellipsis " ⤵"
        org-link-descriptive t
        org-hide-emphasis-markers t)
  (setq org-startup-folded t)
  (setq org-support-shift-select t)

  (setq org-agenda-start-with-log-mode t)
  (setq org-log-done 'time)
  (setq org-log-into-drawer t)
  (setq org-startup-with-inline-images t)
  (setq org-export-headline-levels 6)
  (setq org-image-actual-width nil)
  (setq org-format-latex-options '(:foreground "White" :background default :scale 2.0 :html-foreground "Black" :html-background "Transparent" :html-scale 1.0 :matchers ("begin" "$1" "$" "$$" "\\(" "\\[")))

  (setq org-agenda-files '("/home/swarsel/Nextcloud/Org/Tasks.org"
                           "/home/swarsel/Nextcloud/Org/Archive.org"
                           ))

  (setq org-refile-targets
        '((swarsel-archive-org-file :maxlevel . 1)
          (swarsel-tasks-org-file :maxlevel . 1)))

  )

(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :init
  (setq org-appear-autolinks t)
  (setq org-appear-autokeywords t)
  (setq org-appear-autoentities t)
  (setq org-appear-autosubmarkers t))

(use-package visual-fill-column
  :hook (org-mode . swarsel/org-mode-visual-fill))

(setq org-fold-core-style 'overlays)

(setq org-src-preserve-indentation nil)

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (python . t)
   (js . t)
   (shell . t)
   ))

(push '("conf-unix" . conf-unix) org-src-lang-modes)

(setq org-export-with-broken-links 'mark)
(setq org-confirm-babel-evaluate nil)

;; tangle is too slow, try to speed it up
(defadvice org-babel-tangle-single-block (around inhibit-redisplay activate protect compile)
  "inhibit-redisplay and inhibit-message to avoid flicker."
  (let ((inhibit-redisplay t)
        (inhibit-message t))
    ad-do-it))

(defadvice org-babel-tangle (around time-it activate compile)
  "Display the execution time"
  (let ((tim (current-time)))
    ad-do-it
    (message "org-tangle took %f sec" (float-time (time-subtract (current-time) tim)))))

(require 'org-tempo)
(add-to-list 'org-structure-template-alist '("sh" . "src shell"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("py" . "src python :results output"))
(add-to-list 'org-structure-template-alist '("nix" . "src nix-ts :tangle"))

(use-package auctex)
(setq TeX-auto-save t)
(setq TeX-save-query nil)
(setq TeX-parse-self t)
(setq-default TeX-engine 'luatex)
(setq-default TeX-master nil)

(add-hook 'LaTeX-mode-hook 'visual-line-mode)
(add-hook 'LaTeX-mode-hook 'flyspell-mode)
(add-hook 'LaTeX-mode-hook 'LaTeX-math-mode)
(add-hook 'LaTeX-mode-hook 'reftex-mode)
(setq LaTeX-electric-left-right-brace t)
(setq font-latex-fontify-script nil)
(setq TeX-electric-sub-and-superscript t)
;; (setq reftex-plug-into-AUCTeX t)



(use-package org-fragtog)
(add-hook 'org-mode-hook 'org-fragtog-mode)
(add-hook 'markdown-mode-hook 'org-fragtog-mode)

(use-package org-modern
  :config (setq org-modern-block-name
                '((t . t)
                  ("src" "»" "∥")))
  :hook (org-mode . org-modern-mode))

(use-package org-present
  :bind (:map org-present-mode-keymap
              ("q" . org-present-quit)
              ("<left>" . swarsel/org-present-prev)
              ("<up>" . 'ignore)
              ("<down>" . 'ignore)
              ("<right>" . swarsel/org-present-next))
  :hook ((org-present-mode . swarsel/org-present-start)
         (org-present-mode-quit . swarsel/org-present-end))
  )


(use-package hide-mode-line)

(defun swarsel/org-present-start ()
  (setq-local face-remapping-alist '((default (:height 1.5) variable-pitch)
                                     (header-line (:height 4.0) variable-pitch)
                                     (org-document-title (:height 1.75) org-document-title)
                                     (org-code (:height 1.55) org-code)
                                     (org-verbatim (:height 1.55) org-verbatim)
                                     (org-block (:height 1.25) org-block)
                                     (org-block-begin-line (:height 0.7) org-block)
                                     ))
  (dolist (face '((org-level-1 . 1.1)
                  (org-level-2 . 1.2)
                  (org-level-3 . 1.2)
                  (org-level-4 . 1.2)
                  (org-level-5 . 1.2)
                  (org-level-6 . 1.2)
                  (org-level-7 . 1.2)
                  (org-level-8 . 1.2)))
    (set-face-attribute (car face) nil :font swarsel-alt-font :weight 'medium :height (cdr face)))

  (setq header-line-format " ")
  (setq visual-fill-column-width 90)
  (setq indicate-buffer-boundaries nil)
  (setq inhibit-message nil)
  ;; (breadcrumb-mode 0)
  (org-display-inline-images)
  (global-hl-line-mode 0)
  ;; (display-line-numbers-mode 0)
  (org-modern-mode 0)
  (evil-insert-state 1)
  (beginning-of-buffer)
  (org-present-read-only)
  ;; (org-present-hide-cursor)
  (swarsel/org-present-slide)
  )

(defun swarsel/org-present-end ()
  (setq-local face-remapping-alist '((default variable-pitch default)))
  (dolist (face '((org-level-1 . 1.1)
                  (org-level-2 . 0.9)
                  (org-level-3 . 0.9)
                  (org-level-4 . 0.9)
                  (org-level-5 . 0.9)
                  (org-level-6 . 0.9)
                  (org-level-7 . 0.9)
                  (org-level-8 . 0.9)))
    (set-face-attribute (car face) nil :font swarsel-alt-font :weight 'medium :height (cdr face)))
  (setq header-line-format nil)
  (setq visual-fill-column-width 150)
  (setq indicate-buffer-boundaries t)
  (setq inhibit-message nil)
  ;; (breadcrumb-mode 1)
  (global-hl-line-mode 1)
  ;; (display-line-numbers-mode 1)
  (org-remove-inline-images)
  (org-modern-mode 1)
  (evil-normal-state 1)
  ;; (org-present-show-cursor)
  )

(defun swarsel/org-present-slide ()
  (org-overview)
  (org-show-entry)
  (org-show-children)
  )

(defun swarsel/org-present-prev ()
  (interactive)
  (org-present-prev)
  (swarsel/org-present-slide))

(defun swarsel/org-present-next ()
  (interactive)
  (unless (eobp)
    (org-next-visible-heading 1)
    (org-fold-show-entry))
  (when (eobp)
    (org-present-next)
    (swarsel/org-present-slide)
    ))

(defun clojure-leave-clojure-mode-function ()
  )

(add-hook 'buffer-list-update-hook #'clojure-leave-clojure-mode-function)
(add-hook 'org-present-mode-hook 'swarsel/org-present-start)
(add-hook 'org-present-mode-quit-hook 'swarsel/org-present-end)
(add-hook 'org-present-after-navigate-functions 'swarsel/org-present-slide)

(use-package nix-mode
  :after lsp-mode
  :ensure t
  :hook
  (nix-mode . lsp-deferred) ;; So that envrc mode will work
  :custom
  (lsp-disabled-clients '((nix-mode . nix-nil))) ;; Disable nil so that nixd will be used as lsp-server
  :config
  (setq lsp-nix-nixd-server-path "nixd"
        lsp-nix-nixd-formatting-command [ "nixpkgs-fmt" ]
        lsp-nix-nixd-nixpkgs-expr "import (builtins.getFlake \"/home/swarsel/.dotfiles\").inputs.nixpkgs { }"
        lsp-nix-nixd-nixos-options-expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").nixosConfigurations.nbl-imba-2.options"
        lsp-nix-nixd-home-manager-options-expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").nixosConfigurations.nbl-imba-2.options.home-manager.users.type.getSubOptions []"
        ))

(use-package nix-ts-mode
  :after lsp-mode
  :mode "\\.nix\\'"
  :ensure t
  :hook
  (nix-ts-mode . lsp-deferred) ;; So that envrc mode will work
  :custom
  (lsp-disabled-clients '((nix-ts-mode . nix-nil))) ;; Disable nil so that nixd will be used as lsp-server
  :config
  (setq lsp-nix-nixd-server-path "nixd"
        lsp-nix-nixd-formatting-command [ "nixpkgs-fmt" ]
        lsp-nix-nixd-nixpkgs-expr "import (builtins.getFlake \"/home/swarsel/.dotfiles\").inputs.nixpkgs { }"
        lsp-nix-nixd-nixos-options-expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").nixosConfigurations.nbl-imba-2.options"
        lsp-nix-nixd-home-manager-options-expr "(builtins.getFlake \"/home/swarsel/.dotfiles\").nixosConfigurations.nbl-imba-2.options.home-manager.users.type.getSubOptions []"
        ))


(with-eval-after-load 'lsp-mode
  (lsp-register-client
   (make-lsp-client :new-connection (lsp-stdio-connection "nixd")
                    :major-modes '(nix-mode nix-ts-mode)
                    :priority 0
                    :server-id 'nixd)))

(use-package hcl-mode
  :mode "\\.hcl\\'"
  :config
  (setq hcl-indent-level 2))

(use-package groovy-mode)

(use-package jenkinsfile-mode
  :mode "Jenkinsfile")

(use-package ansible)

(use-package dockerfile-mode
  :mode "Dockerfile")

(use-package terraform-mode
  :mode "\\.tf\\'"
  :config
  (setq terraform-indent-level 2)
  (setq terraform-format-on-save t))

(add-hook 'terraform-mode-hook #'outline-minor-mode)

(use-package nixpkgs-fmt)

(use-package shfmt
  :config
  (setq shfmt-command "shfmt")
  (setq shfmt-arguments '("-i" "4" "-s" "-sr")))

(setq markdown-command "pandoc")

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown")
  :bind (:map markdown-mode-map
              ("C-c C-e" . markdown-do)))

(add-hook 'markdown-mode-hook
          (lambda ()
            (local-set-key (kbd "C-c C-x C-l") 'org-latex-preview)
            (local-set-key (kbd "C-c C-x C-u") 'markdown-toggle-url-hiding)
            ))

(use-package elfeed)

(use-package elfeed-goodies)
(elfeed-goodies/setup)

(setq elfeed-db-directory "~/.elfeed/db/")


(use-package elfeed-protocol
  :after elfeed)

(elfeed-protocol-enable)
(setq elfeed-use-curl t)
(setq elfeed-set-timeout 36000)
(setq elfeed-protocol-enabled-protocols '(fever))
(setq elfeed-protocol-fever-update-unread-only t)
(setq elfeed-protocol-fever-fetch-category-as-tag t)
(setq elfeed-protocol-feeds '(("fever+https://Swarsel@signpost.swarsel.win"
                               :api-url "https://signpost.swarsel.win/api/fever.php"
                               :password-file "~/.emacs.d/.fever")))

(define-key elfeed-show-mode-map (kbd ";") 'visual-fill-column-mode)
(define-key elfeed-show-mode-map (kbd "j") 'elfeed-goodies/split-show-next)
(define-key elfeed-show-mode-map (kbd "k") 'elfeed-goodies/split-show-prev)
(define-key elfeed-search-mode-map (kbd "j") 'next-line)
(define-key elfeed-search-mode-map (kbd "k") 'previous-line)
(define-key elfeed-show-mode-map (kbd "S-SPC") 'scroll-down-command)

(use-package rg)

;; (use-package emacs
;;   :ensure nil
;;   :init
;;   (setq treesit-language-source-alist
;;         '((bash . ("https://github.com/tree-sitter/tree-sitter-bash"))
;;           (c . ("https://github.com/tree-sitter/tree-sitter-c"))
;;           (cmake . ("https://github.com/uyha/tree-sitter-cmake"))
;;           (cpp . ("https://github.com/tree-sitter/tree-sitter-cpp"))
;;           (css . ("https://github.com/tree-sitter/tree-sitter-css"))
;;           (elisp . ("https://github.com/Wilfred/tree-sitter-elisp"))
;;           (go . ("https://github.com/tree-sitter/tree-sitter-go"))
;;           (html . ("https://github.com/tree-sitter/tree-sitter-html"))
;;           (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript"))
;;           (json . ("https://github.com/tree-sitter/tree-sitter-json"))
;;           (julia . ("https://github.com/tree-sitter/tree-sitter-julia"))
;;           (latex . ("https://github.com/latex-lsp/tree-sitter-latex"))
;;           (make . ("https://github.com/alemuller/tree-sitter-make"))
;;           (markdown . ("https://github.com/ikatyang/tree-sitter-markdown"))
;;           (nix . ("https://github.com/nix-community/tree-sitter-nix"))
;;           (R . ("https://github.com/r-lib/tree-sitter-r"))
;;           (python . ("https://github.com/tree-sitter/tree-sitter-python"))
;;           (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" "typescript/src" "typescript"))
;;           (rust . ("https://github.com/tree-sitter/tree-sitter-rust"))
;;           (sql . ("https://github.com/m-novikov/tree-sitter-sql"))
;;           (toml . ("https://github.com/tree-sitter/tree-sitter-toml"))
;;           (tsx  . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src"))
;;           (yaml . ("https://github.com/ikatyang/tree-sitter-yaml"))))
;;   )

(use-package treesit-auto
  :custom
  (setq treesit-auto-install t)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;; (use-package direnv
;;   :custom (direnv-always-show-summary nil)
;;   :config (direnv-mode))

(use-package envrc
  :hook (after-init . envrc-global-mode))

(use-package avy
  :bind
  (("M-o" . avy-goto-char-timer))
  :config
  (setq avy-all-windows 'all-frames))

(use-package devdocs)

(add-hook 'python-mode-hook
          (lambda () (setq-local devdocs-current-docs '("python~3.12" "numpy~1.23" "matplotlib~3.7" "pandas~1"))))
(add-hook 'python-ts-mode-hook
          (lambda () (setq-local devdocs-current-docs '("python~3.12" "numpy~1.23" "matplotlib~3.7" "pandas~1"))))

(add-hook 'c-mode-hook
          (lambda () (setq-local devdocs-current-docs '("c"))))
(add-hook 'c-ts-mode-hook
          (lambda () (setq-local devdocs-current-docs '("c"))))

(add-hook 'c++-mode-hook
          (lambda () (setq-local devdocs-current-docs '("cpp"))))
(add-hook 'c++-ts-mode-hook
          (lambda () (setq-local devdocs-current-docs '("cpp"))))

                                        ; (devdocs-update-all)

(use-package projectile
  :diminish projectile-mode
  :config (projectile-mode)
  :custom ((projectile-completion-system 'auto)) ;; integrate ivy into completion system
  :bind-keymap
  ("C-c p" . projectile-command-map) ; all projectile commands under this
  :init
  ;; NOTE: Set this to the folder where you keep your Git repos!
  (when (file-directory-p swarsel-work-projects-directory)
    (when (file-directory-p swarsel-private-projects-directory)
      (setq projectile-project-search-path (list swarsel-work-projects-directory swarsel-private-projects-directory))))
  (setq projectile-switch-project-action #'magit-status))

(use-package magit
  :config
  (setq magit-repository-directories `((,swarsel-work-projects-directory  . 1)
                                       (,swarsel-private-projects-directory . 1)
                                       ("~/.dotfiles/" . 0)))
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)) ; stay in the same window

;; yubikey support for pushing commits
;; commiting is enabled through nixos gpg-agent config
(use-package pinentry)
(pinentry-start)
(setq epg-pinentry-mode 'loopback)
(setenv "SSH_AUTH_SOCK" (string-chop-newline (shell-command-to-string "gpgconf --list-dirs agent-ssh-socket")))

(use-package forge
  :after magit)

(use-package git-timemachine
  :hook (git-time-machine-mode . evil-normalize-keymaps)
  :init (setq git-timemachine-show-minibuffer-details t))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package highlight-parentheses
  :config
  (setq highlight-parentheses-colors '("black" "white" "black" "black" "black" "black" "black"))
  (setq highlight-parentheses-background-colors '("magenta" "blue" "cyan" "green" "yellow" "orange" "red"))
  (global-highlight-parentheses-mode t))

;; (electric-pair-mode 1)
;; (setq electric-pair-preserve-balance t)
;; (setq electric-pair-skip-self nil)
;; (setq electric-pair-delete-adjacent-pairs t)
;; don't skip newline when auto-pairing parenthesis
;; (setq electric-pair-skip-whitespace-chars '(9 32))

;; in org-mode buffers, do not pair < and > in order not to interfere with org-tempo
;; (add-hook 'org-mode-hook (lambda ()
;;                            (setq-local electric-pair-inhibit-predicate
;;                                        `(lambda (c)
;;                                           (if (char-equal c ?<) t (,electric-pair-inhibit-predicate c))))))

(use-package rainbow-mode
  :config (rainbow-mode))

(use-package corfu
  :init
  (global-corfu-mode)
  (corfu-history-mode)
  (corfu-popupinfo-mode) ; Popup completion info
  :custom
  (corfu-auto t)
  (corfu-auto-prefix 3)
  (corfu-auto-delay 1)
  (corfu-cycle t)
  (corfu-quit-no-match 'separator)
  (corfu-separator ?\s)
  ;; (corfu-quit-no-match t)
  (corfu-popupinfo-max-height 70)
  (corfu-popupinfo-delay '(0.5 . 0.2))
  ;; (corfu-preview-current 'insert) ; insert previewed candidate
  (corfu-preselect 'prompt)
  (corfu-on-exact-match nil)      ; Don't auto expand tempel snippets
  ;; Optionally use TAB for cycling, default is `corfu-complete'.
  :bind (:map corfu-map
              ("M-SPC"      . corfu-insert-separator)
              ("<return>" . swarsel/corfu-normal-return)
              ;; ("C-<return>" . swarsel/corfu-complete)
              ("S-<up>" . corfu-popupinfo-scroll-down)
              ("S-<down>" . corfu-popupinfo-scroll-up)
              ("C-<up>" . corfu-previous)
              ("C-<down>" . corfu-next)
              ("<insert-state> <up>"      . swarsel/corfu-quit-and-up)
              ("<insert-state> <down>"     . swarsel/corfu-quit-and-down))
  )

(use-package nerd-icons-corfu)

(add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter)

(setq nerd-icons-corfu-mapping
      '((array :style "cod" :icon "symbol_array" :face font-lock-type-face)
        (boolean :style "cod" :icon "symbol_boolean" :face font-lock-builtin-face)
        ;; ...
        (t :style "cod" :icon "code" :face font-lock-warning-face)))

(use-package cape
  :bind
  ("C-z p" . completion-at-point) ;; capf
  ("C-z t" . complete-tag)        ;; etags
  ("C-z d" . cape-dabbrev)        ;; or dabbrev-completion
  ("C-z h" . cape-history)
  ("C-z f" . cape-file)
  ("C-z k" . cape-keyword)
  ("C-z s" . cape-elisp-symbol)
  ("C-z e" . cape-elisp-block)
  ("C-z a" . cape-abbrev)
  ("C-z l" . cape-line)
  ("C-z w" . cape-dict)
  ("C-z :" . cape-emoji)
  ("C-z \\" . cape-tex)
  ("C-z _" . cape-tex)
  ("C-z ^" . cape-tex)
  ("C-z &" . cape-sgml)
  ("C-z r" . cape-rfc1345)
  )

;;(use-package rustic
;;  :init
;;  (setq rust-mode-treesitter-derive t)
;;  :config
;;  (define-key rust-ts-mode-map (kbd "C-c C-c C-r") 'rustic-cargo-run)
;;  (define-key rust-ts-mode-map (kbd "C-c C-c C-b") 'rustic-cargo-build)
;;  (define-key rust-ts-mode-map (kbd "C-c C-c C-k") 'rustic-cargo-check)
;;  (define-key rust-ts-mode-map (kbd "C-c C-c d") 'rustic-cargo-doc)
;; (define-key rust-ts-mode-map (kbd "C-c C-c a") 'rustic-cargo-add)
;;  (setq rustic-format-on-save t)
;;  (setq rustic-lsp-client 'eglot)
;;  :mode ("\\.rs" . rustic-mode))

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

(setq vterm-tramp-shells '(("ssh" "'sh'")))

(use-package diff-hl
  :hook
  ((prog-mode
    org-mode) . diff-hl-mode)
  :init
  (diff-hl-flydiff-mode)
  (diff-hl-margin-mode)
  (diff-hl-show-hunk-mouse-mode))

(use-package evil-nerd-commenter
  :bind ("M-/" . evilnc-comment-or-uncomment-lines))

(use-package eglot
  :hook
  ((python-mode
    python-ts-mode
    c-mode
    c-ts-mode
    c++-mode
    c++-ts-mode
    go-mode
    go-ts-mode
    ;;rust-ts-mode
    ;;rustic-mode
    tex-mode
    LaTeX-mode
    ) . (lambda () (progn
                     (eglot-ensure)
                     (add-hook 'before-save-hook 'eglot-format nil 'local))))
  :custom
  (eldoc-echo-area-use-multiline-p nil)
  (completion-category-defaults nil)
  (fset #'jsonrpc--log-event #'ignore)
  (eglot-events-buffer-size 0)
  (eglot-sync-connect nil)
  (eglot-connect-timeout nil)
  (eglot-autoshutdown t)
  (eglot-send-changes-idle-time 3)
  (flymake-no-changes-timeout 5)
  :bind (:map eglot-mode-map
              ("M-(" . flymake-goto-next-error)
              ("C-c ," . eglot-code-actions)))

(use-package eglot-booster
  :ensure nil
  :after eglot
  :config
  (eglot-booster-mode))

(defalias 'start-lsp-server #'eglot)

(use-package lsp-mode
  :init
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  (setq lsp-keymap-prefix "C-c l")
  (setq lsp-auto-guess-root "t")
  :commands lsp)

;; (use-package company)

;; thanks to https://tecosaur.github.io/emacs-config/config.html#lsp-support-src
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

(use-package lsp-bridge
  :ensure nil)

(use-package sideline-flymake
  :hook (flymake-mode . sideline-mode)
  :init
  (setq sideline-flymake-display-mode 'point) ; 'point to show errors only on point
                                        ; 'line to show errors on the current line
  (setq sideline-backends-right '(sideline-flymake)))

(setq backup-by-copying-when-linked t)

(use-package dirvish
  :init
  (dirvish-override-dired-mode)
  :config
  (dirvish-peek-mode)
  (dirvish-side-follow-mode)
  ;; (setq dirvish-open-with-programs
  ;;       (append dirvish-open-with-programs '(
  ;;                                            (("xlsx" "docx" "doc" "odt" "ods") "libreoffice" "%f")
  ;;                                            (("jpg" "jpeg" "png")              "imv" "%f")
  ;;                                            (("pdf")                           "sioyek" "%f")
  ;;                                            (("xopp")                          "xournalpp" "%f"))))
  :custom
  (delete-by-moving-to-trash t)
  (dired-listing-switches
   "-l --almost-all --human-readable --group-directories-first --no-group")
  (dirvish-attributes
   '(vc-state subtree-state nerd-icons collapse file-time file-size))
  (dirvish-quick-access-entries
   '(("h" "~/"              "Home")
     ("c" "~/.dotfiles/"    "Config")
     ("d" "~/Downloads/"    "Downloads")
     ("D" "~/Documents/"    "Documents")
     ("p" "~/Documents/GitHub/"  "Projects")
     ("/" "/"               "Root")))
  :bind
  (("<DUMMY-i> d" . 'dirvish)
   ("C-=" . 'dirvish-side)
   :map dirvish-mode-map
   ("h"   . dired-up-directory)
   ("<left>"   . dired-up-directory)
   ("l"   . dired-find-file)
   ("<right>"   . dired-find-file)
   ("j"   . evil-next-visual-line)
   ("k"   . evil-previous-visual-line)
   ("a"   . dirvish-quick-access)
   ("f"   . dirvish-file-info-menu)
   ("z"   . dirvish-history-last)
   ("J"   . dirvish-history-jump)
   ("y"   . dirvish-yank-menu)
   ("/"   . dirvish-narrow)
   ("TAB" . dirvish-subtree-toggle)
   ("M-f" . dirvish-history-go-forward)
   ("M-b" . dirvish-history-go-backward)
   ("M-l" . dirvish-ls-switches-menu)
   ("M-m" . dirvish-mark-menu)
   ("M-t" . dirvish-layout-toggle)
   ("M-s" . dirvish-setup-menu)
   ("M-e" . dirvish-emerge-menu)
   ("M-j" . dirvish-fd-jump)))

(use-package undo-tree
  :init (global-undo-tree-mode)
  :bind (:map undo-tree-visualizer-mode-map
              ("h" . undo-tree-visualize-switch-branch-left)
              ("l" . undo-tree-visualize-switch-branch-left)
              ("j" . undo-tree-visualize-redo)
              ("k" . undo-tree-visualize-undo))
  :config
  (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo"))))

(use-package hydra)

;; change the text size of the current buffer
(defhydra hydra-text-scale (:timeout 4)
  "scale text"
  ("j" text-scale-increase "in")
  ("k" text-scale-decrease "out")
  ("f" nil "finished" :exit t))

(use-package mu4e
  :ensure nil
  ;; :load-path "/usr/share/emacs/site-lisp/mu4e/"
  ;;:defer 20 ; Wait until 20 seconds after startup
  :config

  ;; This is set to 't' to avoid mail syncing issues when using mbsync
  (setq send-mail-function 'sendmail-send-it)
  (setq mu4e-change-filenames-when-moving t)
  (setq mu4e-mu-binary (executable-find "mu"))
  (setq mu4e-hide-index-messages t)

  (setq mu4e-update-interval 180)
  (setq mu4e-get-mail-command "mbsync -a")
  (setq mu4e-maildir "~/Mail")

  ;; enable inline images
  (setq mu4e-view-show-images t)
  ;; use imagemagick, if available
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
          (:maildir "/Sent Mail"     :key ?s)
          (:maildir "/Trash"     :key ?t)
          (:maildir "/Drafts"     :key ?d)
          (:maildir "/All Mail"     :key ?a)))

  (setq user-mail-address (getenv "SWARSEL_MAIL4")
        user-full-name (getenv "SWARSEL_FULLNAME"))

  ;; this does the equivalent of (setq mu4e-user-mail-address-list '(address1@about.com address2@about.com [...])))
  (setq mu4e-user-mail-address-list
    (mapcar #'intern (split-string (or (getenv "SWARSEL_MAIL_ALL") "") "[ ,]+" t)))
  )


(add-hook 'mu4e-compose-mode-hook #'swarsel/mu4e-send-from-correct-address)
(add-hook 'mu4e-compose-post-hook #'swarsel/mu4e-restore-default)

(use-package mu4e-alert
  :config
  (setq mu4e-alert-set-default-style 'libnotify))

(add-hook 'after-init-hook #'mu4e-alert-enable-notifications)

(mu4e t)

(use-package org-caldav
  :init
  ;; set org-caldav-sync-initalization
  (setq swarsel-caldav-synced 0)
  (setq org-caldav-url "https://stash.swarsel.win/remote.php/dav/calendars/Swarsel")
  (setq org-caldav-calendars
        '((:calendar-id "personal"
                        :inbox "~/Calendars/leon_cal.org")))
  (setq org-caldav-files '("~/Calendars/leon_cal.org"))
  ;; (setq org-caldav-backup-file "~/org-caldav/org-caldav-backup.org")
  ;; (setq org-caldav-save-directory "~/org-caldav/")

  :config
  (setq org-icalendar-alarm-time 1)
  ;; This makes sure to-do items as a category can show up on the calendar
  (setq org-icalendar-include-todo t)
  ;; This ensures all org "deadlines" show up, and show up as due dates
  (setq org-icalendar-use-deadline '(event-if-todo event-if-not-todo todo-due))
  ;; This ensures "scheduled" org items show up, and show up as start times
  (setq org-icalendar-use-scheduled '(todo-start event-if-todo event-if-not-todo))
  )

(use-package calfw
  :ensure nil
  :bind ("C-c A" . swarsel/open-calendar)
  :init
  (use-package calfw-cal
    :ensure nil)
  (use-package calfw-org
    :ensure nil)
  (use-package calfw-ical
    :ensure nil)
  :config
  (bind-key "g" 'cfw:refresh-calendar-buffer cfw:calendar-mode-map)
  (bind-key "q" 'evil-quit cfw:details-mode-map)
  ;; (custom-set-faces
  ;;  '(cfw:face-title ((t (:foreground "#f0dfaf" :weight bold :height 65))))
  ;; )
  )

(defun swarsel/open-calendar ()
  (interactive)
  (unless (eq swarsel-caldav-synced 1) (org-caldav-sync) (setq swarsel-caldav-synced 1))
  ;;  (select-frame (make-frame '((name . "calendar")))) ; makes a new frame and selects it
  ;; (set-face-attribute 'default (selected-frame) :height 65) ; reduces the font size of the new frame
  (cfw:open-calendar-buffer
   :contents-sources
   (list
    (cfw:org-create-source "Purple")  ; orgmode source
    (cfw:ical-create-source "TISS" "https://tiss.tuwien.ac.at/events/rest/calendar/personal?locale=de&token=4463bf7a-87a3-490a-b54c-99b4a65192f3" "Cyan"))))

(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook)
  ;; (setq initial-buffer-choice (lambda () (get-buffer-create "*dashboard*")))
  (setq dashboard-display-icons-p t ;; display icons on both GUI and terminal
        dashboard-icon-type 'nerd-icons ;; use `nerd-icons' package
        dashboard-set-file-icons t
        dashboard-items '((recents . 5)
                          (projects . 5)
                          (agenda . 5))
        dashboard-set-footer nil
        dashboard-banner-logo-title "Welcome to SwarsEmacs!"
        dashboard-image-banner-max-height 300
        dashboard-startup-banner "~/.dotfiles/files/wallpaper/swarsel.png"
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
          ((,""
            "SwarselSocial"
            "Browse Swarsele"
            (lambda (&rest _) (browse-url "instagram.com/Swarsele")))

           (,""
            "SwarselSound"
            "Browse SwarselSound"
            (lambda (&rest _) (browse-url "sound.swarsel.win")) )
           (,""
            "SwarselSwarsel"
            "Browse Swarsel"
            (lambda (&rest _) (browse-url "github.com/Swarsel")) )
           (,""
            "SwarselStash"
            "Browse SwarselStash"
            (lambda (&rest _) (browse-url "stash.swarsel.win")) )
           (,"󰫑"
            "SwarselSport"
            "Browse SwarselSports"
            (lambda (&rest _) (browse-url "social.parkour.wien/@Lenno")))
           )
          (
           (,"󱄅"
            "swarsel.win"
            "Browse swarsel.win"
            (lambda (&rest _) (browse-url "swarsel.win")))
           )
          )))

(use-package vterm
  :ensure t)

(use-package multiple-cursors)

(setq mu4e--log-max-size 1000)
(setq message-log-max 30)
(setq comint-buffer-maximum-size 50)
(add-hook 'comint-output-filter-functions 'comint-truncate-buffer)
