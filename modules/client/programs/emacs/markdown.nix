{
  flake.modules.homeManager.emacs-init = { lib, ... }: {
    config.programs.emacs.init.usePackage.markdown-mode = {
      enable = true;
      bindLocal.markdown-mode-map = {
        "C-c C-e" = "markdown-do";
        "C-c C-x C-l" = "org-latex-preview";
        "C-c C-x C-u" = "markdown-toggle-url-hiding";
      };
      custom = {
        markdown-command = "\"multimarkdown\"";
        markdown-ts-ellipsis = "\" ⤵\"";
        markdown-ts-hide-markup = true;
      };
      hook = [
        "(markdown-mode . swarsel/markdown-block-local-font-lock)"
        "(markdown-ts-mode . swarsel/markdown-ts-mode-setup)"
      ];
      init = ''
        (defun swarsel/markdown-block-local-font-lock ()
          "Stop font-lock from widening every jit-lock chunk to its whole block."
          (remove-hook 'font-lock-extend-region-functions #'markdown-font-lock-extend-region t))

        (defvar-local swarsel/markdown-revealed-line nil)

        (defun swarsel/markdown-reveal-fontify (start end)
          (when swarsel/markdown-revealed-line
            (save-excursion
              (goto-char swarsel/markdown-revealed-line)
              (let ((bol (pos-bol))
                    (eol (pos-bol 2)))
                (when (and (< start eol) (< bol end))
                  (with-silent-modifications
                    (remove-text-properties bol eol '(invisible nil display nil))))))))

        (defun swarsel/markdown-reveal-line ()
          (let ((old swarsel/markdown-revealed-line))
            (unless (and old (= old (pos-bol)))
              (setq swarsel/markdown-revealed-line (copy-marker (pos-bol)))
              (when old
                (save-excursion
                  (goto-char old)
                  (font-lock-flush (pos-bol) (pos-bol 2))))
              (font-lock-flush (pos-bol) (pos-bol 2)))))

        (defun swarsel-markdown-fontify-table-border (node override start end &rest _)
          (let ((beg (treesit-node-start node))
                (fin (treesit-node-end node)))
            (treesit-fontify-with-override beg fin 'markdown-ts-delimiter override start end)
            (when markdown-ts-hide-markup
              (put-text-property beg fin 'display
                                 (cond ((equal (treesit-node-type node) "pipe_table_delimiter_cell")
                                        (make-string (- fin beg) ?─))
                                       ((not (equal (treesit-node-type (treesit-node-parent node)) "pipe_table_delimiter_row"))
                                        "│")
                                       ((not (treesit-node-prev-sibling node)) "├")
                                       ((not (treesit-node-next-sibling node)) "┤")
                                       (t "┼"))))))

        (defun swarsel/markdown-ts-mode-setup ()
          (variable-pitch-mode 1)
          (visual-line-mode 1)
          (setq-local treesit-font-lock-settings
                      (append treesit-font-lock-settings
                              (treesit-font-lock-rules
                               :language 'markdown
                               :feature 'paragraph
                               :override 'prepend
                               '("|" @swarsel-markdown-fontify-table-border
                                 (pipe_table_delimiter_cell) @swarsel-markdown-fontify-table-border))))
          (add-hook 'jit-lock-functions #'swarsel/markdown-reveal-fontify 90 t)
          (add-hook 'post-command-hook #'swarsel/markdown-reveal-line nil t))

        (with-eval-after-load 'markdown-ts-mode
          (keymap-set markdown-ts-mode-map "C-c C-x C-l" #'org-latex-preview)
          (keymap-set markdown-ts-mode-map "C-c C-x C-u" #'markdown-ts-toggle-hide-markup)

          (dotimes (level 6)
            (set-face-attribute (intern (format "markdown-ts-heading-%d" (1+ level))) nil
                                :inherit (intern (format "org-level-%d" (1+ level)))
                                :weight 'unspecified))
          (set-face-attribute 'markdown-ts-code-span nil :inherit 'org-code)
          (set-face-attribute 'markdown-ts-code-block nil :inherit 'org-block)
          (set-face-attribute 'markdown-ts-code-block-markup-hidden nil :background 'unspecified :inherit 'org-block)
          (set-face-attribute 'markdown-ts-table nil :inherit 'org-block)
          (set-face-attribute 'markdown-ts-table-header nil :inherit '(org-table markdown-ts-table) :weight 'bold))
      '';
      mode = lib.mkForce [ ];
    };
  };
}
