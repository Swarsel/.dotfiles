{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.mixed-pitch = {
    enable = true;
    custom = {
      mixed-pitch-set-height = false;
      mixed-pitch-variable-pitch-cursor = false;
    };
    hook = [ "(text-mode . mixed-pitch-mode)" ];
  };
}
