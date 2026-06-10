{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    which-key = {
      enable = true;
      init = "(which-key-mode)";
      diminish = [ "which-key-mode" ];
      custom = {
        which-key-idle-delay = 0.3;
      };
    };

    helpful = {
      enable = true;
      bind = {
        "C-h f" = "helpful-callable";
        "C-h v" = "helpful-variable";
        "C-h k" = "helpful-key";
        "C-h C-." = "helpful-at-point";
      };
      custom = {
        help-window-select = false;
      };
    };
  };
}
