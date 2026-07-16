{
  flake.modules.homeManager.emacs-init.config.programs.emacs.init.usePackage.shfmt = {
    enable = true;
    custom = {
      shfmt-arguments = '''("-i" "4" "-s" "-sr")'';
      shfmt-command = ''"shfmt"'';
    };
  };
}
