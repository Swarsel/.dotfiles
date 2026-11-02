{
  flake.modules.homeManager.emacs-init =
    { lib, pkgs, ... }:
    let
      python = ''"${lib.getExe pkgs.python3}"'';
    in
    {
      config.programs.emacs.init.usePackage.python = {
        enable = true;
        custom = {
          org-babel-python-command = python;
          python-indent-guess-indent-offset-verbose = false;
          python-shell-interpreter = python;
        };
      };
    };
}
