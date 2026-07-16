{
  flake.modules.homeManager.emacs-init = {
    config.programs.emacs.init.usePackage.general = {
      config = ''
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
      '';
      enable = true;
      init = ''
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
      '';
    };
  };
}
