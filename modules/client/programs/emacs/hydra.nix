{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    general.config = ''
      (swarsel/leader-keys
        "ts" '(hydra-text-scale/body :which-key "scale text"))
    '';

    hydra = {
      enable = true;
      config = ''
        (defhydra hydra-text-scale (:timeout 4)
          "scale text"
          ("j" text-scale-increase "in")
          ("k" text-scale-decrease "out")
          ("f" nil "finished" :exit t))
      '';
    };
  };
}
