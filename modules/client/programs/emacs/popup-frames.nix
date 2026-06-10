{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.prelude = ''
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
  '';
}
