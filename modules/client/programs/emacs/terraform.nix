{
  flake.modules.homeManager.emacs-init = { lib, ... }: {
    config.programs.emacs.init.usePackage.terraform-mode = {
      enable = true;
      mode = lib.mkForce [ ''"\\.tf\\'"'' ];
      hook = [ "(terraform-mode . outline-minor-mode)" ];
      custom = {
        terraform-indent-level = 2;
        terraform-format-on-save = true;
      };
    };
  };
}
