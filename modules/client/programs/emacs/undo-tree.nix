{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.undo-tree = {
    config = ''
      (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))

      (defun swarsel/clear-undo-tree ()
        (interactive)
        (setq buffer-undo-tree nil))

      (define-advice undo-list-transfer-to-tree (:around (orig-fun &rest args) ignore-gc)
        (cl-letf (((symbol-function 'garbage-collect) #'ignore))
          (apply orig-fun args)))
    '';
    enable = true;
    bindLocal.undo-tree-visualizer-mode-map = {
      "h" = "undo-tree-visualize-switch-branch-left";
      "j" = "undo-tree-visualize-redo";
      "k" = "undo-tree-visualize-undo";
      "l" = "undo-tree-visualize-switch-branch-left";
    };
    init = "(global-undo-tree-mode)";
  };
}
