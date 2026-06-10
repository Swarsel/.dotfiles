{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.hcl-mode = {
    enable = true;
    mode = [ ''"\\.hcl\\'"'' ];
    custom = {
      hcl-indent-level = 2;
    };
  };
}
