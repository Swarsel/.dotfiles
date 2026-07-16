{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.pulsar = {
    config = ''
      (pulsar-global-mode 1)
      (with-eval-after-load 'consult
        (add-hook 'consult-after-jump-hook #'pulsar-recenter-top)
        (add-hook 'consult-after-jump-hook #'pulsar-reveal-entry))
    '';
    enable = true;
    custom = {
      pulsar-face = "'pulsar-green";
      pulsar-highlight-face = "'pulsar-cyan";
      pulsar-pulse = true;
    };
  };
}
