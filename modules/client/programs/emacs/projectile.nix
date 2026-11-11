{
  flake.modules.homeManager.emacs-init = { config, lib, ... }: {
    config.programs.emacs.init.usePackage = {
      general.config = ''
        (swarsel/leader-keys
          "lp" '((lambda () (interactive) (projectile-switch-project)) :which-key "switch project"))
      '';

      projectile = {
        config = "(projectile-mode)";
        enable = true;
        bindKeyMap."C-c p" = "projectile-command-map";
        custom.projectile-completion-system = "'auto";
        diminish = [ "projectile-mode" ];
        init = ''
          (let ((dirs (list ${lib.optionalString (builtins.elem "optional-work" config.swarselsystems.enabledHomeModules) "swarsel-work-projects-directory "}swarsel-private-projects-directory)))
            (when (seq-every-p #'file-directory-p dirs)
              (setq projectile-project-search-path dirs)))
          (setq projectile-switch-project-action #'magit-status)
        '';
      };
    };
  };
}
