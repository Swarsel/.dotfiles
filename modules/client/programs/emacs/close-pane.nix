{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.prelude = ''
    (defun swarsel/kill-buffer-delete-window ()
      (let ((win (get-buffer-window (current-buffer))))
        (when (and win (not (one-window-p)))
          (delete-window win))))

    (add-hook 'kill-buffer-hook #'swarsel/kill-buffer-delete-window)
  '';
}
