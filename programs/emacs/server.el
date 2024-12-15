;; package setup here
(require 'package)

(package-initialize nil)
(setq package-enable-at-startup nil)

(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)

(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)

(add-to-list 'package-archives
             '("marmalade" .
               "http://marmalade-repo.org/packages/"))

(package-initialize)

;; general add packages to list
(let ((default-directory  "~/.emacs.d/elpa/"))
  (normal-top-level-add-subdirs-to-load-path))

;; make sure 'use-package is installed
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;;; use-package
(require 'use-package)

;; Load elfeed
(use-package elfeed
  :ensure t
  :bind (:map elfeed-search-mode-map
                                        ;              ("A" . bjm/elfeed-show-all)
                                        ;              ("E" . bjm/elfeed-show-emacs)
                                        ;              ("D" . bjm/elfeed-show-daily)
              ("q" . bjm/elfeed-save-db-and-bury)))

(require 'elfeed)

;; Load elfeed-org
(use-package elfeed-org
  :ensure t
  :config
  (elfeed-org)
  (setq rmh-elfeed-org-files (list "/Vault/data/syncthing/.elfeed/elfeed.org"))
  )

;; Laod elfeed-goodies
(use-package elfeed-goodies
  :ensure t
  )

(elfeed-goodies/setup)

;; Load elfeed-web
(use-package elfeed-web
  :ensure t
  )

;;; Elfeed
(global-set-key (kbd "C-x w") 'bjm/elfeed-load-db-and-open)

(define-key elfeed-show-mode-map (kbd "j") 'elfeed-goodies/split-show-next)
(define-key elfeed-show-mode-map (kbd "k") 'elfeed-goodies/split-show-prev)
(define-key elfeed-search-mode-map (kbd "j") 'next-line)
(define-key elfeed-search-mode-map (kbd "k") 'previous-line)
(define-key elfeed-show-mode-map (kbd "S-SPC") 'scroll-down-command)


;;write to disk when quiting
(defun bjm/elfeed-save-db-and-bury ()
  "Wrapper to save the elfeed db to disk before burying buffer"
  (interactive)
  (elfeed-db-save)
  (quit-window))

;;functions to support syncing .elfeed between machines
;;makes sure elfeed reads index from disk before launching
(defun bjm/elfeed-load-db-and-open ()
  "Wrapper to load the elfeed db from disk before opening"
  (interactive)
  (elfeed-db-load)
  (elfeed)
  (elfeed-search-update--force)
  (elfeed-update))

(defun bjm/elfeed-updater ()
  "Wrapper to load the elfeed db from disk before opening"
  (interactive)
  (elfeed-db-save)
  (quit-window)
  (elfeed-db-load)
  (elfeed)
  (elfeed-search-update--force)
  (elfeed-update))

(run-with-timer 0 (* 30 60) 'bjm/elfeed-updater)

(setq httpd-port 9812)   ; replace NNNNN with a port equalling your start port + 10 (or whatever)
(setq httpd-host "0.0.0.0")   ; replace NNNNN with a port equalling your start port + 10 (or whatever)
(setq httpd-root "/home/swarsel/.emacs.d/elpa/elfeed-web-20240729.1741/")   ; replace NNNNN with a port equalling your start port + 10 (or whatever)

(httpd-start)
(elfeed-web-start)

;; /home/swarsel/.emacs.d/elpa/elfeed-web-20240729.1741/
