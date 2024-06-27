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
  (setq user-mail-address "leon@swarsel.win"
        user-full-name "Leon Schwarzäugl"))

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
  (org-indent-mode)
  (variable-pitch-mode 1)
  ;;(auto-fill-mode 0)
  (setq display-line-numbers-type 'relative
        display-line-numbers-current-absolute 1
        display-line-numbers-width-start nil
        display-line-numbers-width 6
        display-line-numbers-grow-only 1)
  (add-hook 'org-tab-first-hook 'org-end-of-line)
  (visual-line-mode 1))

(defun swarsel/org-mode-visual-fill ()
  (setq visual-fill-column-width 150
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1))

(defun swarsel/org-babel-tangle-config ()
  (when (string-equal (buffer-file-name)
                      swarsel-swarsel-org-filepath)
    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      (org-html-export-to-html)
      (org-babel-tangle)))
  (when (string-equal (buffer-file-name)
                      swarsel-emacs-org-filepath)
    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      (org-html-export-to-html)
      (org-babel-tangle)))
  (when (string-equal (buffer-file-name)
                      swarsel-nix-org-filepath)
    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))

(setq org-html-htmlize-output-type nil)

(add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'swarsel/org-babel-tangle-config)))

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

;; run the python inferior shell immediately upon entering a python buffer
    ;; (add-hook 'python-mode-hook 'swarsel/run-python)

  ;; (defun swarsel/run-python ()
  ;;   (save-selected-window
  ;;     (switch-to-buffer-other-window (process-buffer (python-shell-get-or-create-process (python-shell-parse-command))))))

;; reload python shell automatically
(defun my-python-shell-run ()
  (interactive)
  (when (get-buffer-process "*Python*")
     (set-process-query-on-exit-flag (get-buffer-process "*Python*") nil)
     (kill-process (get-buffer-process "*Python*"))
     ;; Uncomment If you want to clean the buffer too.
     ;;(kill-buffer "*Python*")
     ;; Not so fast!
     (sleep-for 0.5))
  (run-python (python-shell-parse-command) nil nil)
  (python-shell-send-buffer)
  ;; Pop new window only if shell isnt visible
  ;; in any frame.
  (unless (get-buffer-window "*Python*" t)
    (python-shell-switch-to-shell)))

(defun my-python-shell-run-region ()
  (interactive)
  (python-shell-send-region (region-beginning) (region-end))
  (python-shell-switch-to-shell))

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
    "o"  '(:ignore o :which-key "org")
    "op" '((lambda () (interactive) (org-present)) :which-key "org-present")
    "ob" '((lambda () (interactive) (org-babel-mark-block)) :which-key "Mark whole src-block")
    "ol" '((lambda () (interactive) (org-insert-link)) :which-key "insert link")
    "os" '((lambda () (interactive) (org-store-link)) :which-key "store link")
    "od" '((lambda () (interactive) (org-babel-demarcate-block)) :which-key "demarcate (split) src-block")
    ;; "c"  '(:ignore c :which-key "capture")
    ;; "cj" '((lambda () (interactive) (org-capture nil "jj")) :which-key "journal")
    ;; "cs" '(markdown-download-screenshot :which-key "screenshot")
    "l"  '(:ignore l :which-key "links")
    "lc" '((lambda () (interactive) (progn (find-file swarsel-swarsel-org-filepath) (org-overview) )) :which-key "SwarselSystems.org")
    "le" '((lambda () (interactive) (progn (find-file swarsel-swarsel-org-filepath) (goto-char (org-find-exact-headline-in-buffer "Emacs") ) (org-overview) (org-cycle) )) :which-key "Emacs.org")
    "ln" '((lambda () (interactive) (progn (find-file swarsel-swarsel-org-filepath) (goto-char (org-find-exact-headline-in-buffer "System") ) (org-overview) (org-cycle))) :which-key "Nixos.org")
    "ls" '((lambda () (interactive) (find-file "/smb:Swarsel@192.168.1.3:")) :which-key "Server")
    "lo" '(dired swarsel-obsidian-vault-directory :which-key "obsidian")
    ;; "la" '((lambda () (interactive) (find-file swarsel-org-anki-filepath)) :which-key "anki")
    ;; "ln" '((lambda () (interactive) (find-file swarsel-nix-org-filepath)) :which-key "Nix.org")
    "lp" '((lambda () (interactive) (projectile-switch-project)) :which-key "switch project")
    "lg" '((lambda () (interactive) (magit-list-repositories)) :which-key "list git repos")
    ;; "a"   '(:ignore a :which-key "anki")
    ;; "ap"  '(anki-editor-push-tree :which-key "push new cards")
    ;; "an"  '((lambda () (interactive) (org-capture nil "a")) :which-key "new card")
    ;; "as"  '(swarsel-anki-set-deck-and-notetype :which-key "change deck and notetype")
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
    "wh"  'windmove-left
    "wk"  'windmove-up
    "wj"  'windmove-down
    "wr"  'winner-redo
    "wd"  'delete-window
    "w="  'balance-windows-area
    "wD"  'kill-buffer-and-window
    "wu"  'winner-undo
    "wr"  'winner-redo
    "w/"  'evil-window-vsplit
    "w-"  'evil-window-split
    "wm"  '(delete-other-windows :wk "maximize")
    ))

;; General often used hotkeys
(general-define-key
 "C-M-a" (lambda () (interactive) (org-capture nil "a")) ; make new anki card
 ;; "C-M-d" 'swarsel-obsidian-daily ; open daily obsidian file and create if not exist
 ;; "C-M-S" 'swarsel-anki-set-deck-and-notetype ; switch deck and notetype for new anki cards
 ;; "C-M-s" 'markdown-download-screenshot ; wrapper for org-download-screenshot
 "C-c d" 'crux-duplicate-current-line-or-region
 "C-c D" 'crux-duplicate-and-comment-current-line-or-region
 "<DUMMY-m>" 'swarsel/last-buffer
 "M-\\" 'indent-region
 "C-<f9>" 'my-python-shell-run
 )

;; set Nextcloud directory for journals etc.
(setq swarsel-sync-directory "~/Nextcloud"
      swarsel-emacs-directory "~/.emacs.d"
      swarsel-dotfiles-directory "~/.dotfiles"
      swarsel-projects-directory "~/Documents/GitHub")

(setq swarsel-emacs-org-filepath (expand-file-name "Emacs.org" swarsel-dotfiles-directory)
      swarsel-nix-org-filepath (expand-file-name "Nix.org" swarsel-dotfiles-directory)
      swarsel-swarsel-org-filepath (expand-file-name "SwarselSystems.org" swarsel-dotfiles-directory)
      )


;; set Emacs main configuration .org names
(setq swarsel-emacs-org-file "Emacs.org"
      swarsel-anki-org-file "Anki.org"
      swarsel-tasks-org-file "Tasks.org"
      swarsel-archive-org-file "Archive.org"
      swarsel-org-folder-name "Org"
      swarsel-obsidian-daily-folder-name "⭐ Personal/Journal"
      swarsel-obsidian-folder-name "Obsidian"
      swarsel-obsidian-vault-name "Main")


;; set directory paths
(setq swarsel-org-directory (expand-file-name swarsel-org-folder-name  swarsel-sync-directory)) ; path to org folder
(setq swarsel-obsidian-directory (expand-file-name swarsel-obsidian-folder-name swarsel-sync-directory)) ; path to obsidian
(setq swarsel-obsidian-vault-directory (expand-file-name swarsel-obsidian-vault-name swarsel-obsidian-directory)) ; path to obsidian vault
(setq swarsel-obsidian-daily-directory (expand-file-name swarsel-obsidian-daily-folder-name swarsel-obsidian-vault-directory)) ; path to obsidian daily folder

;; filepaths to certain documents
(setq swarsel-org-anki-filepath (expand-file-name swarsel-anki-org-file swarsel-org-directory) ; path to anki export file
      swarsel-org-tasks-filepath (expand-file-name swarsel-tasks-org-file swarsel-org-directory)
      swarsel-org-archive-filepath (expand-file-name swarsel-archive-org-file swarsel-org-directory))

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

(setq undo-limit 80000000
      evil-want-fine-undo t
      auto-save-default t
      password-cache-expiry nil
      )
(setq browse-url-browser-function 'browse-url-firefox)
;; disable a keybind that does more harm than good
(global-set-key [remap suspend-frame]
                (lambda ()
                  (interactive)
                  (message "This keybinding is disabled (was 'suspend-frame')")))

(setq visible-bell nil)
(setq initial-major-mode 'fundamental-mode
      initial-scratch-message nil)

(add-hook 'prog-mode-hook 'display-line-numbers-mode)
(add-hook 'text-mode-hook 'display-line-numbers-mode)
(global-visual-line-mode 1)

(setq custom-safe-themes t)

(setq byte-compile-warnings '(not free-vars unresolved noruntime lexical make-local))
;; Make native compilation silent and prune its cache.
(when (native-comp-available-p)
  (setq native-comp-async-report-warnings-errors 'silent) ; Emacs 28 with native compilation
  (setq native-compile-prune-cache t)) ; Emacs 29

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
  (setq evil-respect-visual-line-mode t) ; i am torn on this one
  (setq evil-split-window-below t)
  (setq evil-vsplit-window-right t)
  :config
  (evil-mode 1)
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

;; set the NixOS wordlist by hand
(setq ispell-alternate-dictionary "/nix/store/gjmvnbs97cnw19wnqh9m075cdbhy8r8g-wordlist-WORDLIST")

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

;; these settings used to be in custom.el

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
  (doom-modeline-mode)
  (column-number-mode)
  :custom
  ((doom-modeline-height 22)
   (doom-modeline-indent-info nil)
   (doom-modeline-buffer-encoding nil)))

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
  :custom
  (completion-styles '(orderless flex basic))
  (completion-category-overrides '((file (styles . (partial-completion)))
                                   (eglot (styles orderless)))))

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

(setq auth-sources '( "~/.emacs.d/.caldav" "~/.emacs.d/.authinfo.gpg")
      auth-source-cache-expiry nil) ; default is 2h

(use-package org
  ;;:diminish (org-indent-mode)
  :hook (org-mode . swarsel/org-mode-setup)
  :bind
  (("C-<tab>" . org-fold-outer)
  ("C-c s" . org-store-link))
  :config
  (setq org-ellipsis " ⤵"
        org-link-descriptive t
        org-hide-emphasis-markers t)
  (setq org-startup-folded t)
  (setq org-support-shift-select t)

  ;; (setq org-agenda-start-with-log-mode t)
  ;; (setq org-log-done 'time)
  ;; (setq org-log-into-drawer t)
  (setq org-startup-with-inline-images t)
  (setq org-image-actual-width nil)
  (setq org-format-latex-options '(:foreground "White" :background default :scale 2.0 :html-foreground "Black" :html-background "Transparent" :html-scale 1.0 :matchers ("begin" "$1" "$" "$$" "\\(" "\\[")))

(setq org-agenda-files '("/home/swarsel/Nextcloud/Org/Tasks.org"
                         "/home/swarsel/Nextcloud/Org/Archive.org"
                         "/home/swarsel/Nextcloud/Org/Anki.org"
                         "/home/swarsel/Calendars/leon_cal.org"))

(setq org-refile-targets
      '((swarsel-archive-org-file :maxlevel . 1)
        (swarsel-anki-org-file :maxlevel . 1)
        (swarsel-tasks-org-file :maxlevel . 1)))

(setq org-todo-keywords
      '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d!)")
        (sequence "BACKLOG(b)" "PLAN(p)" "READY(r)" "ACTIVE(a)" "REVIEW(v)" "WAIT(w@/!)" "HOLD(h)" "|" "COMPLETED(c)" "CANC(k@)")))


;; Configure custom agenda views
(setq org-agenda-custom-commands
      '(("d" "Dashboard"
         ((agenda "" ((org-deadline-warning-days 7)))
          (todo "NEXT"
                ((org-agenda-overriding-header "Next Tasks")))
          (tags-todo "agenda/ACTIVE" ((org-agenda-overriding-header "Active Projects")))))

        ("n" "Next Tasks"
         ((todo "NEXT"
                ((org-agenda-overriding-header "Next Tasks")))))

        ("W" "Work Tasks" tags-todo "+work-email")


        ("w" "Workflow Status"
         ((todo "WAIT"
                ((org-agenda-overriding-header "Waiting on External")
                 (org-agenda-files org-agenda-files)))
          (todo "REVIEW"
                ((org-agenda-overriding-header "In Review")
                 (org-agenda-files org-agenda-files)))
          (todo "PLAN"
                ((org-agenda-overriding-header "In Planning")
                 (org-agenda-todo-list-sublevels nil)
                 (org-agenda-files org-agenda-files)))
          (todo "BACKLOG"
                ((org-agenda-overriding-header "Project Backlog")
                 (org-agenda-todo-list-sublevels nil)
                 (org-agenda-files org-agenda-files)))
          (todo "READY"
                ((org-agenda-overriding-header "Ready for Work")
                 (org-agenda-files org-agenda-files)))
          (todo "ACTIVE"
                ((org-agenda-overriding-header "Active Projects")
                 (org-agenda-files org-agenda-files)))
          (todo "COMPLETED"
                ((org-agenda-overriding-header "Completed Projects")
                 (org-agenda-files org-agenda-files)))
          (todo "CANC"
                ((org-agenda-overriding-header "Cancelled Projects")
                 (org-agenda-files org-agenda-files)))))))

(setq org-capture-templates
      `(
        ("a" "Anki basic"
         entry
         (file+headline swarsel-org-anki-filepath "Dispatch")
         (function swarsel-anki-make-template-string))

        ("A" "Anki cloze"
         entry
         (file+headline org-swarsel-anki-file "Dispatch")
         "* %<%H:%M>\n:PROPERTIES:\n:ANKI_NOTE_TYPE: Cloze\n:ANKI_DECK: 🦁 All::01 ❤️ Various::00 ✨ Allgemein\n:END:\n** Text\n%?\n** Extra\n")
        ("t" "Tasks / Projects")
        ("tt" "Task" entry (file+olp swarsel-org-tasks-filepath "Inbox")
         "* TODO %?\n  %U\n  %a\n  %i" :empty-lines 1)
        ))
)

;; Set faces for heading levels
(with-eval-after-load 'org-faces  (dolist (face '((org-level-1 . 1.1)
                                                  (org-level-2 . 0.9)
                                                  (org-level-3 . 0.9)
                                                  (org-level-4 . 0.9)
                                                  (org-level-5 . 0.9)
                                                  (org-level-6 . 0.9)
                                                  (org-level-7 . 0.9)
                                                  (org-level-8 . 0.9)))
                                    (set-face-attribute (car face) nil :font swarsel-alt-font :weight 'medium :height (cdr face)))

                      ;; Ensure that anything that should be fixed-pitch in Org files appears that way
                      (set-face-attribute 'org-block nil   :inherit 'fixed-pitch)
                      (set-face-attribute 'org-table nil   :inherit 'fixed-pitch)
                      (set-face-attribute 'org-formula nil   :inherit 'fixed-pitch)
                      (set-face-attribute 'org-code nil :inherit '(shadow fixed-pitch))
                      (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
                      (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
                      (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
                      (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch))

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

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (python . t)
   (js . t)
   (shell . t)
   ))

(push '("conf-unix" . conf-unix) org-src-lang-modes)

(require 'org-tempo)
(add-to-list 'org-structure-template-alist '("sh" . "src shell"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("py" . "src python :results output"))
(add-to-list 'org-structure-template-alist '("nix" . "src nix :tangle"))

(use-package auctex)
(setq TeX-auto-save t)
(setq TeX-save-query nil)
(setq TeX-parse-self t)
  (setq-default TeX-master nil)

(add-hook 'LaTeX-mode-hook 'visual-line-mode)
(add-hook 'LaTeX-mode-hook 'flyspell-mode)
(add-hook 'LaTeX-mode-hook 'LaTeX-math-mode)
(add-hook 'LaTeX-mode-hook 'reftex-mode)
(setq LaTeX-electric-left-right-brace t)
(setq font-latex-fontify-script nil)
(setq TeX-electric-sub-and-superscript t)
  ;; (setq reftex-plug-into-AUCTeX t)

(use-package org-download
  :after org
  :defer nil
  :custom
  (org-download-method 'directory)
  (org-download-image-dir "./images")
  (org-download-heading-lvl 0)
  (org-download-timestamp "org_%Y%m%d-%H%M%S_")
  ;;(org-image-actual-width 500)
  (org-download-screenshot-method "grim -g \"$(slurp)\" %s")
  :bind
  ("C-M-y" . org-download-screenshot)
  :config
  (require 'org-download))

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
      (breadcrumb-mode 0)
      (org-display-inline-images)
      (global-hl-line-mode 0)
      (display-line-numbers-mode 0)
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
           (breadcrumb-mode 1)
           (global-hl-line-mode 1)
           (display-line-numbers-mode 1)
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
  :mode "\\.nix\\'")

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

(use-package olivetti
  :init
  (setq olivetti-body-width 100)
  (setq olivetti-recall-visual-line-mode-entry-state t))

(use-package darkroom
  :init
  (setq darkroom-text-scale-increase 3))

(use-package rg)

(use-package emacs
  :ensure nil
  :init
  (setq treesit-language-source-alist
        '((bash . ("https://github.com/tree-sitter/tree-sitter-bash"))
          (c . ("https://github.com/tree-sitter/tree-sitter-c"))
          (cmake . ("https://github.com/uyha/tree-sitter-cmake"))
          (cpp . ("https://github.com/tree-sitter/tree-sitter-cpp"))
          (css . ("https://github.com/tree-sitter/tree-sitter-css"))
          (elisp . ("https://github.com/Wilfred/tree-sitter-elisp"))
          (go . ("https://github.com/tree-sitter/tree-sitter-go"))
          (html . ("https://github.com/tree-sitter/tree-sitter-html"))
          (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript"))
          (json . ("https://github.com/tree-sitter/tree-sitter-json"))
          (julia . ("https://github.com/tree-sitter/tree-sitter-julia"))
          (latex . ("https://github.com/latex-lsp/tree-sitter-latex"))
          (make . ("https://github.com/alemuller/tree-sitter-make"))
          (markdown . ("https://github.com/ikatyang/tree-sitter-markdown"))
          (R . ("https://github.com/r-lib/tree-sitter-r"))
          (python . ("https://github.com/tree-sitter/tree-sitter-python"))
          (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" "typescript/src" "typescript"))
          (rust . ("https://github.com/tree-sitter/tree-sitter-rust"))
          (sql . ("https://github.com/m-novikov/tree-sitter-sql"))
          (toml . ("https://github.com/tree-sitter/tree-sitter-toml"))
          (tsx  . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src"))
          (yaml . ("https://github.com/ikatyang/tree-sitter-yaml"))))
  )

(use-package treesit-auto
  :config
  (global-treesit-auto-mode)
  (setq treesit-auto-install 'prompt))

(use-package direnv
  :custom (direnv-always-show-summary nil)
  :config (direnv-mode))

(use-package avy
  :bind
  (("M-o" . avy-goto-char-timer))
  :config
  (setq avy-all-windows 'all-frames))

(use-package crdt)

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

(devdocs-update-all)

(use-package projectile
  :diminish projectile-mode
  :config (projectile-mode)
  :custom ((projectile-completion-system 'auto)) ;; integrate ivy into completion system
  :bind-keymap
  ("C-c p" . projectile-command-map) ; all projectile commands under this
  :init
  ;; NOTE: Set this to the folder where you keep your Git repos!
  (when (file-directory-p swarsel-projects-directory)
    (setq projectile-project-search-path (list swarsel-projects-directory)))
(setq projectile-switch-project-action #'magit-status))

(use-package magit
  :config
  (setq magit-repository-directories `((,swarsel-projects-directory  . 1)
                                       (,swarsel-emacs-directory . 0)
                                       (,swarsel-obsidian-directory . 0)
                                       ("~/.dotfiles/" . 0)))
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)) ; stay in the same window

;; yubikey support for pushing commits
;; commiting is enabled through nixos gpg-agent config
(setq epg-pinentry-mode 'loopback)
(setenv "SSH_AUTH_SOCK" (string-chop-newline (shell-command-to-string "gpgconf --list-dirs agent-ssh-socket")))

(use-package forge
  :after magit)

(with-eval-after-load 'forge
  (add-to-list 'forge-alist
               '("sgit.iue.tuwien.ac.at"
                 "sgit.iue.tuwien.ac.at/api/v1"
                 "sgit.iue.tuwien.ac.at"
                 forge-gitea-repository)))

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

  (electric-pair-mode 1)
  (setq electric-pair-preserve-balance nil)
  ;; don't try to be overly smart
  (setq electric-pair-delete-adjacent-pairs nil)
  ;; don't skip newline when auto-pairing parenthesis
  (setq electric-pair-skip-whitespace-chars '(9 32))

  ;; in org-mode buffers, do not pair < and > in order not to interfere with org-tempo
(add-hook 'org-mode-hook (lambda ()
           (setq-local electric-pair-inhibit-predicate
                   `(lambda (c)
                  (if (char-equal c ?<) t (,electric-pair-inhibit-predicate c))))))

(use-package rainbow-mode
  :config (rainbow-mode))

;; (use-package corfu
;;   :custom
;;   (corfu-cycle t)
;;   :init
;;   (global-corfu-mode))

(use-package corfu
  :init
  (global-corfu-mode)
  (corfu-history-mode)
  (corfu-popupinfo-mode) ; Popup completion info
  :custom
  (corfu-auto t)
  (corfu-auto-prefix 3)
  (corfu-auto-delay 0.3)
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
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.  The order of the functions matters, the
  ;; first function returning a result wins.  Note that the list of buffer-local
  ;; completion functions takes precedence over the global list.
  ;; (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  ;; (add-to-list 'completion-at-point-functions #'cape-file)
  ;; (add-to-list 'completion-at-point-functions #'cape-elisp-block)
  ;; (add-to-list 'completion-at-point-functions #'cape-history)
  ;; (add-to-list 'completion-at-point-functions #'cape-keyword)
  ;; (add-to-list 'completion-at-point-functions #'cape-tex)
  ;; (add-to-list 'completion-at-point-functions #'cape-sgml)
  ;; (add-to-list 'completion-at-point-functions #'cape-rfc1345)
  ;; (add-to-list 'completion-at-point-functions #'cape-abbrev)
  ;; (add-to-list 'completion-at-point-functions #'cape-dict)
  ;; (add-to-list 'completion-at-point-functions #'cape-elisp-symbol)
  ;; (add-to-list 'completion-at-point-functions #'cape-line)
)

(use-package rustic
  :init
  (setq rust-mode-treesitter-derive t)
  :config
  (setq rustic-format-on-save t)
  (setq rustic-lsp-client 'eglot)
  :mode ("\\.rs" . rustic-mode))

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

(use-package yasnippet
  :init (yas-global-mode 1)
  :config
  (yas-reload-all))

(setq wtf/latex-mathbb-prefix "''")
(setq swarsel/latex-mathcal-prefix "``")

(use-package yasnippet
  :config

  (setq wtf/english-alphabet
        '("a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z"))

  (dolist (elem wtf/english-alphabet)
    (when (string-equal elem (downcase elem))
      (add-to-list 'wtf/english-alphabet (upcase elem))))


  (yas-define-snippets
   'latex-mode
   (mapcar
    (lambda (elem)
      (list (concat wtf/latex-mathbb-prefix elem) (concat "\\mathbb{" elem "}") (concat "Mathbb letter " elem)))
    wtf/english-alphabet))

  (yas-define-snippets
   'latex-mode
   (mapcar
    (lambda (elem)
      (list (concat swarsel/latex-mathcal-prefix elem) (concat "\\mathcal{" elem "}") (concat "Mathcal letter " elem)))
    wtf/english-alphabet))

  (setq swtf/latex-math-symbols
        '(("x" . "\\times")
          ("*" . "\\cdot")
          ("." . "\\ldots")
          ("op" . "\\operatorname{$1}$0")
          ("o" . "\\circ")
          ("V" . "\\forall")
          ("v" . "\\vee")
          ("w" . "\\wedge")
          ("q" . "\\quad")
          ("f" . "\\frac{$1}{$2}$0")
          ("s" . "\\sum_{$1}^{$2}$0")
          ("p" . "\\prod_{$1}^{$2}$0")
          ("e" . "\\exists")
          ("i" . "\\int_{$1}^{$2}$0")
          ("c" . "\\cap")
          ("u" . "\\cup")
          ("0" . "\\emptyset")))

  )

(use-package eglot
  :ensure nil
  :hook
  ((python-mode
    python-ts-mode
    c-mode
    c-ts-mode
    c++-mode
    c++-ts-mode
    rustic-mode
    rust-ts-mode
    tex-mode
    LaTeX-mode
    ) . (lambda () (progn
                     (eglot-ensure)
                     (add-hook 'before-save-hook 'eglot-format nil 'local))))
  :custom
  (eldoc-echo-area-use-multiline-p nil)
  (completion-category-defaults nil)
  :bind (:map eglot-mode-map
              ("M-(" . flymake-goto-next-error)
              ("C-c ," . eglot-code-actions)))

(defalias 'start-lsp-server #'eglot)

(use-package breadcrumb
  :config (breadcrumb-mode))

(setq backup-by-copying-when-linked t)

(use-package dirvish
  :init
  (dirvish-override-dired-mode)
  :config
  (dirvish-peek-mode)
  (dirvish-side-follow-mode)
  (setq dirvish-open-with-programs
        (append dirvish-open-with-programs '(
                                             (("xlsx" "docx" "doc" "odt" "ods") "libreoffice" "%f")
                                             (("jpg" "jpeg" "png")              "imv" "%f")
                                             (("pdf")                           "sioyek" "%f")
                                             (("xopp")                          "xournalpp" "%f"))))
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

(use-package pdf-tools
  :init
  (if (not (boundp 'pdf-tools-directory))
      (pdf-tools-install))
  :mode ("\\.pdf" . pdf-view-mode))

(use-package ein)

(use-package undo-tree
  ;; :init (global-undo-tree-mode)
  :bind (:map undo-tree-visualizer-mode-map
              ("h" . undo-tree-visualize-switch-branch-left)
              ("l" . undo-tree-visualize-switch-branch-left)
              ("j" . undo-tree-visualize-redo)
              ("k" . undo-tree-visualize-undo))
  :config
  (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo"))))

(add-hook 'prog-mode-hook 'undo-tree-mode)
(add-hook 'text-mode-hook 'undo-tree-mode)
(add-hook 'org-mode-hook 'undo-tree-mode)
(add-hook 'latex-mode-hook 'undo-tree-mode)

(use-package hydra)

;; change the text size of the current buffer
(defhydra hydra-text-scale (:timeout 4)
  "scale text"
  ("j" text-scale-increase "in")
  ("k" text-scale-decrease "out")
  ("f" nil "finished" :exit t))

;; (use-package obsidian
;;   :ensure t
;;   :demand t
;;   :config
;;   (obsidian-specify-path swarsel-obsidian-vault-directory)
;;   (global-obsidian-mode t)
;;   :custom
;;   ;; This directory will be used for `obsidian-capture' if set.
;;   (obsidian-inbox-directory "Inbox")
;;   (bind-key (kbd "C-c M-o") 'obsidian-hydra/body 'obsidian-mode-map)
;;   :bind (:map obsidian-mode-map
;;               ;; Replace C-c C-o with Obsidian.el's implementation. It's ok to use another key binding.
;;               ("C-c C-o" . obsidian-follow-link-at-point)
;;               ;; Jump to backlinks
;;               ("C-c C-b" . obsidian-backlink-jump)
;;               ;; If you prefer you can use `obsidian-insert-link'
;;               ("C-c C-l" . obsidian-insert-wikilink)))

;; (use-package anki-editor
;;   :after org
;;   :bind (:map org-mode-map
;;               ("<f12>" . anki-editor-cloze-region-auto-incr)
;;               ("<f11>" . anki-editor-cloze-region-dont-incr)
;;               ("<f10>" . anki-editor-reset-cloze-number)
;;               ("<f9>"  . anki-editor-push-tree))
;;   :hook (org-capture-after-finalize . anki-editor-reset-cloze-number) ; Reset cloze-number after each capture.
;;   :config
;;   (setq anki-editor-create-decks t ;; Allow anki-editor to create a new deck if it doesn't exist
;;         anki-editor-org-tags-as-anki-tags t)

;;   (defun anki-editor-cloze-region-auto-incr (&optional arg)
;;     "Cloze region without hint and increase card number."
;;     (interactive)
;;     (anki-editor-cloze-region swarsel-anki-editor-cloze-number "")
;;     (setq swarsel-anki-editor-cloze-number (1+ swarsel-anki-editor-cloze-number))
;;     (forward-sexp))
;;   (defun anki-editor-cloze-region-dont-incr (&optional arg)
;;     "Cloze region without hint using the previous card number."
;;     (interactive)
;;     (anki-editor-cloze-region (1- swarsel-anki-editor-cloze-number) "")
;;     (forward-sexp))
;;   (defun anki-editor-reset-cloze-number (&optional arg)
;;     "Reset cloze number to ARG or 1"
;;     (interactive)
;;     (setq swarsel-anki-editor-cloze-number (or arg 1)))
;;   (defun anki-editor-push-tree ()
;;     "Push all notes under a tree."
;;     (interactive)
;;     (anki-editor-push-notes '(4))
;;     (anki-editor-reset-cloze-number))
;;   ;; Initialize
;;   (anki-editor-reset-cloze-number)
;;   )

;; (require 'anki-editor)

;; (defvar swarsel-anki-deck nil)
;; (defvar swarsel-anki-notetype nil)
;; (defvar swarsel-anki-fields nil)

;; (defun swarsel-anki-set-deck-and-notetype ()
;;   (interactive)
;;   (setq swarsel-anki-deck  (completing-read "Choose a deck: "
;;                                             (sort (anki-editor-deck-names) #'string-lessp)))
;;   (setq swarsel-anki-notetype (completing-read "Choose a note type: "
;;                                                (sort (anki-editor-note-types) #'string-lessp)))
;;   (setq swarsel-anki-fields (progn
;;                               (anki-editor--anki-connect-invoke-result "modelFieldNames" `((modelName . ,swarsel-anki-notetype)))))
;;   )

;; (defun swarsel-anki-make-template-string ()
;;   (if (not swarsel-anki-deck)
;;       (call-interactively 'swarsel-anki-set-deck-and-notetype))
;;   (setq swarsel-temp swarsel-anki-fields)
;;   (concat (concat "* %<%H:%M>\n:PROPERTIES:\n:ANKI_NOTE_TYPE: " swarsel-anki-notetype "\n:ANKI_DECK: " swarsel-anki-deck "\n:END:\n** ")(pop swarsel-temp) "\n%?\n** " (mapconcat 'identity swarsel-temp "\n\n** ") "\n\n"))

;; (defun swarsel-today()
;;   (format-time-string "%Y-%m-%d"))

;; (defun swarsel-obsidian-daily ()
;;   (interactive)
;;   (if (not (file-exists-p (expand-file-name (concat (swarsel-today) ".md") swarsel-obsidian-daily-directory)))
;;       (write-region "" nil (expand-file-name (concat (swarsel-today) ".md") swarsel-obsidian-daily-directory))
;;     )
;;   (find-file (expand-file-name (concat (swarsel-today) ".md") swarsel-obsidian-daily-directory)))

;; (let ((mu4epath
;;        (concat
;;         (f-dirname
;;          (file-truename
;;           (executable-find "mu")))
;;         "/../share/emacs/site-lisp/mu4e")))
;;   (when (and
;;          (string-prefix-p "/nix/store/" mu4epath)
;;          (file-directory-p mu4epath))
;;     (add-to-list 'load-path mu4epath)))

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

(setq user-mail-address "leon@swarsel.win"
      user-full-name "Leon Schwarzäugl")


(setq mu4e-user-mail-address-list '(leon.schwarzaeugl@gmail.com leon@swarsel.win nautilus.dw@gmail.com mrswarsel@gmail.com)))


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
  (setq org-caldav-url "https://stash.swarsel.win/remote.php/dav/calendars/Swarsele")
  (setq org-caldav-calendars
        '((:calendar-id "personal"
                        :inbox "~/Calendars/leon_cal.org")))
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
        dashboard-startup-banner "~/.dotfiles/wallpaper/swarsel.png"
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
