(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)

(setq frame-inhibit-implied-resize t)

 (setq default-frame-alist
        (append
         (list
          '(undecorated . t)
          '(min-height . 1)
          '(height     . 42)
          '(min-width  . 1)
          '(width      . 100)
          '(vertical-scroll-bars . nil)
          '(internal-border-width . 10)
          '(tool-bar-lines . 0)
          '(menu-bar-lines . 0))))

 (setq-default left-margin-width 1
                right-margin-width 1)

 (add-hook
   'after-make-frame-functions
   (defun setup-blah-keys (frame)
     (with-selected-frame frame
       (when (display-graphic-p)
         (define-key input-decode-map (kbd "C-i") [C-i])
         (define-key input-decode-map (kbd "C-[") [C-lsb])
         (define-key input-decode-map (kbd "C-m") [C-m])
         ))))

(defun swarsel/last-buffer () (interactive) (switch-to-buffer nil))
(global-set-key (kbd "<C-m>") #'swarsel/last-buffer)

(setq comp-deferred-compilation nil)
