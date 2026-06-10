{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    doom-modeline = {
      enable = false;
      custom = {
        doom-modeline-height = 22;
        doom-modeline-indent-info = false;
        doom-modeline-buffer-encoding = false;
      };
    };

    mini-modeline = {
      enable = true;
      after = [ "smart-mode-line" ];
      custom = {
        mini-modeline-display-gui-line = false;
        mini-modeline-enhance-visual = false;
        mini-modeline-truncate-p = false;
        mini-modeline-l-format = false;
        mini-modeline-right-padding = 5;
        mini-modeline-r-format = ''
          '("%e" mode-line-front-space mode-line-mule-info mode-line-client mode-line-modified mode-line-remote mode-line-frame-identification mode-line-buffer-identification " " mode-line-position " " mode-name evil-mode-line-tag)'';
      };
      config = ''
        (mini-modeline-mode t)
        (setq window-divider-default-places t
              window-divider-default-bottom-width 1
              window-divider-default-right-width 1)
        (window-divider-mode 1)
      '';
    };

    smart-mode-line = {
      enable = true;
      config = ''
        (sml/setup)
        (add-to-list 'sml/replacer-regexp-list '("^~/Documents/Work/" ":WK:"))
        (add-to-list 'sml/replacer-regexp-list '("^~/Documents/Private/" ":PR:"))
        (add-to-list 'sml/replacer-regexp-list '("^~/.dotfiles/" ":D:") t)
      '';
    };
  };
}
