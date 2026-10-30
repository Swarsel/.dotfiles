{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    doom-themes = {
      config = ''
        (load-theme 'doom-city-lights t)
        (doom-themes-treemacs-config)
        (doom-themes-org-config)
        (custom-set-faces '(gnus-group-news-low ((t (:weight bold)))))
      '';
      enable = true;
      hook = [ "(server-after-make-frame . swarsel/load-theme-once)" ];
      init = ''
        (defun swarsel/load-theme-once ()
          (when (display-graphic-p)
            (load-theme 'doom-city-lights t)
            (remove-hook 'server-after-make-frame-hook #'swarsel/load-theme-once)))
      '';
    };
    solaire-mode = {
      enable = true;
      custom.solaire-global-mode = "+1";
    };
  };
}
