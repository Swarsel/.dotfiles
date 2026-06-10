{
  flake.modules.homeManager.emacs-init = { lib, ... }: {
    config.programs.emacs.init.usePackage.dockerfile-mode = {
      enable = true;
      mode = lib.mkForce [ ''"Dockerfile"'' ];
    };
  };
}
