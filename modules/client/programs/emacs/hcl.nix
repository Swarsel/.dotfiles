{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.hcl-mode = {
    enable = true;
    custom.hcl-indent-level = 2;
    mode = [ ''"\\.hcl\\'"'' ];
  };
}
