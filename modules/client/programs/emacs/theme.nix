{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    doom-themes = {
      config = ''
        (load-theme 'doom-city-lights t)
        (doom-themes-treemacs-config)
        (doom-themes-org-config)
        (with-eval-after-load 'gnus
          (put 'gnus-group-news-low 'face-defface-spec '((t (:weight bold)))))
      '';
      enable = true;
      hook = [ "(server-after-make-frame . (lambda () (load-theme 'doom-city-lights t)))" ];
    };
    solaire-mode = {
      enable = true;
      custom.solaire-global-mode = "+1";
    };
  };
}
