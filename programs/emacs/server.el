(require 'package)

(package-initialize nil)
(setq package-enable-at-startup nil)

(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)

(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)


(package-initialize)

(let ((default-directory  "~/.emacs.d/elpa/"))
  (normal-top-level-add-subdirs-to-load-path))

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)

(use-package elfeed
  :ensure t
  :bind (:map elfeed-search-mode-map
              ("q" . bjm/elfeed-save-db-and-bury)))

(require 'elfeed)

(use-package elfeed-org
  :ensure t
  :config
  (elfeed-org)
  (setq rmh-elfeed-org-files (list "/var/lib/syncthing/.elfeed/elfeed.org")))

(use-package elfeed-goodies
  :ensure t)

(elfeed-goodies/setup)

(use-package elfeed-web
  :ensure t)

(global-set-key (kbd "C-x w") 'bjm/elfeed-load-db-and-open)

(define-key elfeed-show-mode-map (kbd "j") 'elfeed-goodies/split-show-next)
(define-key elfeed-show-mode-map (kbd "k") 'elfeed-goodies/split-show-prev)
(define-key elfeed-search-mode-map (kbd "j") 'next-line)
(define-key elfeed-search-mode-map (kbd "k") 'previous-line)
(define-key elfeed-show-mode-map (kbd "S-SPC") 'scroll-down-command)


(defun bjm/elfeed-save-db-and-bury ()
  "Wrapper to save the elfeed db to disk before burying buffer"
  (interactive)
  (elfeed-db-save)
  (quit-window))

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

(setq httpd-port 9812)
(setq httpd-host "0.0.0.0")
(setq httpd-root "/root/.emacs.d/elpa/elfeed-web-20240729.1741/")

(httpd-start)
(elfeed-web-start)
