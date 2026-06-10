{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    general.config = ''
      (swarsel/leader-keys
        "eo" '(evil-jump-backward :which-key "cursor jump backwards")
        "eO" '(evil-jump-forward :which-key "cursor jump forwards")
        "te" '(swarsel/toggle-evil-state :which-key "emacs/evil")
        "tp" '(evil-cleverparens-mode :wk "cleverparens"))
    '';

    evil = {
      enable = true;
      init = ''
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
      '';
      config = ''
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
      '';
    };

    evil-collection = {
      enable = true;
      after = [ "evil" ];
      config = "(evil-collection-init)";
    };

    evil-snipe = {
      enable = true;
      after = [ "evil" ];
      demand = true;
      config = ''
        (evil-snipe-mode +1)
        (evil-snipe-override-mode +1)
      '';
    };

    evil-cleverparens.enable = true;

    evil-surround = {
      enable = true;
      config = "(global-evil-surround-mode 1)";
    };

    evil-visual-mark-mode = {
      enable = true;
      command = [ "evil-visual-mark-mode" ];
    };

    evil-textobj-tree-sitter = {
      enable = true;
      config = ''
        (define-key evil-outer-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.outer"))
        (define-key evil-inner-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.inner"))
        (define-key evil-outer-text-objects-map "a" (evil-textobj-tree-sitter-get-textobj ("if_statement.outer" "conditional.outer" "loop.outer") '((python-mode . ((if_statement.outer) @if_statement.outer)) (python-ts-mode . ((if_statement.outer) @if_statement.outer)))))
      '';
    };

    evil-numbers.enable = true;

    evil-mc = {
      enable = true;
      after = [ "evil" ];
      config = "(global-evil-mc-mode 1)";
    };

    evil-nerd-commenter = {
      enable = true;
      bind = {
        "M-/" = "evilnc-comment-or-uncomment-lines";
      };
    };
  };
}
