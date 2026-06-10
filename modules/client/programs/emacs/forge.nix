{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.forge = {
    enable = true;
    after = [ "magit" ];
    init = "(setq forge-add-default-bindings nil)";
  };
}
