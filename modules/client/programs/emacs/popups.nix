{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    general.config = ''
      (swarsel/leader-keys
        "mp" '(popper-toggle :which-key "popper"))
    '';

    popper = {
      enable = true;
      bind."M-[" = "popper-toggle";
      init = ''
        (setq popper-reference-buffers
              '("\\*Messages\\*"
                ("\\*Warnings\\*" . hide)
                "Output\\*$"
                "\\*Async Shell Command\\*"
                "\\*Async-native-compile-log\\*"
                help-mode
                helpful-mode
                "*Occur*"
                "*scratch*"
                "*julia*"
                "*Python*"
                "*rustic-compilation*"
                "*cargo-run*"
                (compilation-mode . hide)))
        (popper-mode +1)
        (popper-echo-mode +1)
      '';
    };

    shackle = {
      config = ''
        (setq shackle-rules '(("*Messages*" :select t :popup t :align right :size 0.3)
                              ("*Warnings*" :ignore t :popup t :align right :size 0.3)
                              ("*Occur*" :select t :popup t :align below :size 0.2)
                              ("*scratch*" :select t :popup t :align below :size 0.2)
                              ("*Python*" :select t :popup t :align below :size 0.2)
                              ("*rustic-compilation*" :select t :popup t :align below :size 0.4)
                              ("*cargo-run*" :select t :popup t :align below :size 0.2)
                              ("*tex-shell*" :ignore t :popup t :align below :size 0.2)
                              (helpful-mode :select t :popup t :align right :size 0.35)
                              (help-mode :select t :popup t :align right :size 0.4)))
        (shackle-mode 1)
      '';
      enable = true;
    };
  };
}
