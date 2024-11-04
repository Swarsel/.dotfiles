(defvar swarsel-file-name-handler-alist file-name-handler-alist)
(defvar swarsel-vc-handled-backends vc-handled-backends)

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6
      file-name-handler-alist nil
      vc-handled-backends nil)

(add-hook 'emacs-startup-hook
          (lambda ()
            (progn
              ;; (setq gc-cons-threshold (* 1000 1000 8)
              ;; (setq gc-cons-threshold #x40000000
                 (setq gc-cons-threshold (* 32 1024 1024)
                    gc-cons-percentage 0.1
                    jit-lock-defer-time 0.05
                    read-process-output-max (* 1024 1024)
                    file-name-handler-alist swarsel-file-name-handler-alist
                    vc-handled-backends swarsel-vc-handled-backends)
              (fset 'epg-wait-for-status 'ignore)
              )))

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
      inhibit-startup-echo-area-message user-login-name ; this needs to be set to the username or it will not have an effect
      comp-deferred-compilation nil ; compile all Elisp to native code immediately
      )

(setq-default left-margin-width 1
              right-margin-width 1)

(setq-default default-frame-alist
              (append
               (list
                '(undecorated . t) ; no title bar, borders etc.
                '(background-color . "#1D252C") ; load doom-citylight colors to avoid white flash
                '(foreground-color . "#A0B3C5") ; load doom-citylight colors to avoid white flash
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
