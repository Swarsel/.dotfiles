{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    general.config = ''
      (swarsel/leader-keys
        "md" '(dirvish :which-key "dirvish"))
    '';

    dirvish = {
      enable = true;
      init = "(dirvish-override-dired-mode)";
      config = ''
        (dirvish-peek-mode)
        (dirvish-side-follow-mode)
      '';
      custom = {
        delete-by-moving-to-trash = true;
        dired-listing-switches = ''
          "-l --almost-all --human-readable --group-directories-first --no-group"'';
        dirvish-attributes = "'(vc-state subtree-state nerd-icons collapse file-time file-size)";
        dirvish-quick-access-entries = ''
          '(("h" "~/"              "Home")
            ("c" "~/.dotfiles/"    "Config")
            ("d" "~/Downloads/"    "Downloads")
            ("D" "~/Documents/"    "Documents")
            ("p" "~/Documents/GitHub/"  "Projects")
            ("/" "/"               "Root"))'';
      };
      bind = {
        "<DUMMY-i> d" = "'dirvish";
        "C-=" = "'dirvish-side";
      };
      bindLocal.dirvish-mode-map = {
        "h" = "dired-up-directory";
        "<left>" = "dired-up-directory";
        "l" = "dired-find-file";
        "<right>" = "dired-find-file";
        "j" = "evil-next-visual-line";
        "k" = "evil-previous-visual-line";
        "a" = "dirvish-quick-access";
        "f" = "dirvish-file-info-menu";
        "z" = "dirvish-history-last";
        "J" = "dirvish-history-jump";
        "y" = "dirvish-yank-menu";
        "/" = "dirvish-narrow";
        "TAB" = "dirvish-subtree-toggle";
        "M-f" = "dirvish-history-go-forward";
        "M-b" = "dirvish-history-go-backward";
        "M-l" = "dirvish-ls-switches-menu";
        "M-m" = "dirvish-mark-menu";
        "M-t" = "dirvish-layout-toggle";
        "M-s" = "dirvish-setup-menu";
        "M-e" = "dirvish-emerge-menu";
        "M-j" = "dirvish-fd-jump";
      };
    };
  };
}
