{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.undo-tree = {
    enable = true;
    init = "(global-undo-tree-mode)";
    bindLocal.undo-tree-visualizer-mode-map = {
      "h" = "undo-tree-visualize-switch-branch-left";
      "l" = "undo-tree-visualize-switch-branch-left";
      "j" = "undo-tree-visualize-redo";
      "k" = "undo-tree-visualize-undo";
    };
    config = ''
      (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))

      (defun swarsel/clear-undo-tree ()
        (interactive)
        (setq buffer-undo-tree nil))

      (define-advice undo-list-transfer-to-tree (:around (orig-fun &rest args) ignore-gc)
        (cl-letf (((symbol-function 'garbage-collect) #'ignore))
          (apply orig-fun args)))
    '';
  };
}
