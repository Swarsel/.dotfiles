{
  flake.modules.homeManager.emacs-init =
    { lib, pkgs, ... }:
    let
      shfmt = ''"${lib.getExe pkgs.shfmt}"'';
    in
    {
      config.programs.emacs.init.usePackage.shfmt = {
        config = ''
          (with-eval-after-load 'apheleia
            (setf (car (alist-get 'shfmt apheleia-formatters)) ${shfmt}))
        '';
        enable = true;
        custom = {
          shfmt-arguments = '''("-i" "4" "-s" "-sr")'';
          shfmt-command = shfmt;
        };
      };
    };
}
