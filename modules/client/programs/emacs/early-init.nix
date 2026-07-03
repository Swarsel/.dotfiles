{
  flake.modules.homeManager.emacs-init =
    { config, ... }:
    {
      config.programs.emacs.init = {
        earlyInit = ''
          (defvar swarsel-file-name-handler-alist file-name-handler-alist)
          (defvar swarsel-vc-handled-backends vc-handled-backends)

          (defun swarsel/restore-startup-settings ()
            "Restore startup-tuned variables to their regular runtime values."
            (unless (featurep 'mps)
              (setq gc-cons-threshold (* 100 1024 1024)
                    gc-cons-percentage 0.1))
            (setq jit-lock-defer-time 0.05
                  read-process-output-max (* 1024 1024)
                  file-name-handler-alist swarsel-file-name-handler-alist
                  vc-handled-backends swarsel-vc-handled-backends)
            (fset 'epg-wait-for-status #'ignore))

          (unless (featurep 'mps)
            (setq gc-cons-threshold most-positive-fixnum
                  gc-cons-percentage 0.6))
          (setq file-name-handler-alist nil
                vc-handled-backends nil)

          (add-hook 'emacs-startup-hook #'swarsel/restore-startup-settings)

          (tool-bar-mode 0)
          (menu-bar-mode 0)
          (scroll-bar-mode 0)

          (setq frame-inhibit-implied-resize t
                ring-bell-function 'ignore
                use-dialog-box nil
                use-file-dialog nil
                use-short-answers t
                inhibit-startup-message t
                inhibit-splash-screen t
                inhibit-startup-screen t
                inhibit-x-resources t
                inhibit-startup-buffer-menu t
                inhibit-startup-echo-area-message user-login-name
                comp-deferred-compilation nil)

          (setq-default left-margin-width 1
                        right-margin-width 1)

          (setq-default default-frame-alist
                        (append
                         (list
                          '(undecorated . t)
                          '(background-color . "${config.lib.stylix.colors.withHashtag.base00}")
                          '(foreground-color . "${config.lib.stylix.colors.withHashtag.base05}")
                          '(font . "FiraCode Nerd Font")
                          '(vertical-scroll-bars . nil)
                          '(horizontal-scroll-bars . nil)
                          '(internal-border-width . 5)
                          '(tool-bar-lines . 0)
                          '(menu-bar-lines . 0))))

          (add-hook
           'after-make-frame-functions
           (lambda (frame)
             (with-selected-frame frame
               (when (display-graphic-p)
                 (define-key input-decode-map (kbd "C-i") [DUMMY-i])
                 (define-key input-decode-map (kbd "C-[") [DUMMY-lsb])
                 (define-key input-decode-map (kbd "C-m") [DUMMY-m])
                 ))))
        '';
      };
    };
}
