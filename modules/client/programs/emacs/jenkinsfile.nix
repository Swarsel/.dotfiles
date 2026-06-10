{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage = {
    groovy-mode.enable = true;

    jenkinsfile-mode = {
      enable = true;
      mode = [ ''"Jenkinsfile"'' ];
    };
  };
}
