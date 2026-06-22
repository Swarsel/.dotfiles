{
  flake.modules.homeManager.emacs-init =
    { pkgs, ... }:
    let
      claude-code-ide =
        epkgs:
        epkgs.trivialBuild rec {
          pname = "claude-code-ide";
          version = "20260402";
          src = pkgs.fetchFromGitHub {
            owner = "manzaltu";
            repo = "claude-code-ide.el";
            rev = "56db02ee386d009ddb8b1482310f1f9beeefb810";
            hash = "sha256-qH1QnG5G+0UiH/v0KaS7oSpQZY+BkUMZvrjbx6kyFhg=";
          };
          packageRequires = [
            epkgs.websocket
            epkgs.transient
            epkgs.web-server
            epkgs.vterm
          ];
        };
    in
    {
      config.programs.emacs.init.usePackage.claude-code-ide = {
        enable = true;
        package = claude-code-ide;
        bind = {
          "C-c c" = "claude-code-ide-menu";
        };
        config = ''
          (claude-code-ide-emacs-tools-setup)

          (defun diego--vterm-font-setup ()
            "Configure font settings specifically for vterm buffers, workaround claude-code."
            (let ((tbl (or buffer-display-table (setq buffer-display-table (make-display-table)))))
              (dolist (pair
                       '((#x273B . ?*)
                         (#x273D . ?*)
                         (#x2722 . ?+)
                         (#x2736 . ?+)
                         (#x2733 . ?*)
                         ))
                (aset tbl (car pair) (vector (cdr pair))))))

          (add-hook 'vterm-mode-hook #'diego--vterm-font-setup)
        '';
      };
    };
}
