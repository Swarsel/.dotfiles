{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.pedantix = {
    config = ''
      (with-eval-after-load 'apheleia
        (setf (alist-get 'nix-mode apheleia-mode-alist) nil
              (alist-get 'nix-ts-mode apheleia-mode-alist) nil))
    '';
    enable = true;
    hook = [
      "(nix-mode . pedantix-format-on-save-mode)"
      "(nix-ts-mode . pedantix-format-on-save-mode)"
    ];
  };
}
