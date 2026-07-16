{
  flake.modules.homeManager.emacs-init = { lib, ... }: {
    config.programs.emacs.init.usePackage.terraform-mode = {
      enable = true;
      custom = {
        terraform-format-on-save = true;
        terraform-indent-level = 2;
      };
      hook = [ "(terraform-mode . outline-minor-mode)" ];
      mode = lib.mkForce [ ''"\\.tf\\'"'' ];
    };
  };
}
