{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    dirvish = {
      config = ''
        (dirvish-peek-mode)
        (dirvish-side-follow-mode)
      '';
      enable = true;
      bind = {
        "<DUMMY-i> d" = "'dirvish";
        "C-=" = "'dirvish-side";
      };
      bindLocal.dirvish-mode-map = {
        "/" = "dirvish-narrow";
        "<left>" = "dired-up-directory";
        "<right>" = "dired-find-file";
        "J" = "dirvish-history-jump";
        "M-b" = "dirvish-history-go-backward";
        "M-e" = "dirvish-emerge-menu";
        "M-f" = "dirvish-history-go-forward";
        "M-j" = "dirvish-fd-jump";
        "M-l" = "dirvish-ls-switches-menu";
        "M-m" = "dirvish-mark-menu";
        "M-s" = "dirvish-setup-menu";
        "M-t" = "dirvish-layout-toggle";
        "TAB" = "dirvish-subtree-toggle";
        "a" = "dirvish-quick-access";
        "f" = "dirvish-file-info-menu";
        "h" = "dired-up-directory";
        "j" = "evil-next-visual-line";
        "k" = "evil-previous-visual-line";
        "l" = "dired-find-file";
        "y" = "dirvish-yank-menu";
        "z" = "dirvish-history-last";
      };
      custom = {
        delete-by-moving-to-trash = true;
        dired-listing-switches = ''"-l --almost-all --human-readable --group-directories-first --no-group"'';
        dirvish-attributes = "'(vc-state subtree-state nerd-icons collapse file-time file-size)";
        dirvish-quick-access-entries = ''
          '(("h" "~/"              "Home")
            ("c" "~/.dotfiles/"    "Config")
            ("d" "~/Downloads/"    "Downloads")
            ("D" "~/Documents/"    "Documents")
            ("p" "~/Documents/GitHub/"  "Projects")
            ("/" "/"               "Root"))'';
      };
      init = "(dirvish-override-dired-mode)";
    };
    general.config = ''
      (swarsel/leader-keys
        "md" '(dirvish :which-key "dirvish"))
    '';
  };
}
