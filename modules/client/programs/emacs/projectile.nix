{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    general.config = ''
      (swarsel/leader-keys
        "lp" '((lambda () (interactive) (projectile-switch-project)) :which-key "switch project"))
    '';

    projectile = {
      enable = true;
      diminish = [ "projectile-mode" ];
      config = "(projectile-mode)";
      custom = {
        projectile-completion-system = "'auto";
      };
      bindKeyMap = {
        "C-c p" = "projectile-command-map";
      };
      init = ''
        (when (file-directory-p swarsel-work-projects-directory)
          (when (file-directory-p swarsel-private-projects-directory)
            (setq projectile-project-search-path (list swarsel-work-projects-directory swarsel-private-projects-directory))))
        (setq projectile-switch-project-action #'magit-status)
      '';
    };
  };
}
