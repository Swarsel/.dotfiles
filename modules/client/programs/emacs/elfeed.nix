{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    elfeed = {
      config = ''
        (define-key elfeed-show-mode-map (kbd ";") #'visual-fill-column-mode)
        (define-key elfeed-show-mode-map (kbd "j") #'elfeed-goodies/split-show-next)
        (define-key elfeed-show-mode-map (kbd "k") #'elfeed-goodies/split-show-prev)
        (define-key elfeed-search-mode-map (kbd "j") #'next-line)
        (define-key elfeed-search-mode-map (kbd "k") #'previous-line)
        (define-key elfeed-show-mode-map (kbd "S-SPC") #'scroll-down-command)
      '';
      enable = true;
      custom = {
        elfeed-db-directory = ''"~/.elfeed/db/"'';
        elfeed-set-timeout = 36000;
        elfeed-use-curl = true;
      };
    };
    elfeed-goodies = {
      config = "(elfeed-goodies/setup)";
      enable = true;
      after = [ "elfeed" ];
    };
    elfeed-protocol = {
      config = ''
        (elfeed-protocol-enable)
        (let ((domain (getenv "SWARSEL_RSS_DOMAIN")))
          (setq elfeed-protocol-feeds
                `((,(concat "fever+https://Swarsel@" domain)
                   :api-url ,(concat "https://" domain "/api/fever.php")
                   :password-file "~/.emacs.d/.fever"))))
      '';
      enable = true;
      after = [ "elfeed" ];
      custom = {
        elfeed-protocol-enabled-protocols = "'(fever)";
        elfeed-protocol-fever-fetch-category-as-tag = true;
        elfeed-protocol-fever-update-unread-only = true;
      };
    };
    general.config = ''
      (swarsel/leader-keys
        "mr" '(bjm/elfeed-load-db-and-open :which-key "elfeed"))
    '';
  };
}
