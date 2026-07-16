{
  flake.modules.homeManager.emacs-init =
    { pkgs, ... }:
    let
      eglot-booster =
        epkgs:
        epkgs.trivialBuild rec {
          packageRequires = [
            epkgs.jsonrpc
            epkgs.eglot
          ];
          pname = "eglot-booster";
          src = pkgs.fetchFromGitHub {
            hash = "sha256-PLfaXELkdX5NZcSmR1s/kgmU16ODF8bn56nfTh9g6bs=";
            owner = "jdtsmith";
            repo = "eglot-booster";
            rev = "e6daa6bcaf4aceee29c8a5a949b43eb1b89900ed";
          };
          version = "main-29-10-2024";
        };
    in
    {
      config.programs.emacs.init.usePackage = {
        eglot = {
          config = "(fset #'jsonrpc--log-event #'ignore)";
          enable = true;
          bindLocal.eglot-mode-map = {
            "C-c ," = "eglot-code-actions";
            "M-(" = "flymake-goto-next-error";
          };
          custom = {
            eglot-autoshutdown = true;
            eglot-connect-timeout = false;
            eglot-events-buffer-size = 0;
            eglot-send-changes-idle-time = 3;
            eglot-sync-connect = false;
            eldoc-echo-area-prefer-doc-buffer = true;
            eldoc-echo-area-use-multiline-p = false;
            flymake-no-changes-timeout = 5;
          };
          hook = [
            "((python-mode python-ts-mode c-mode c-ts-mode c++-mode c++-ts-mode go-mode go-ts-mode tex-mode LaTeX-mode) . swarsel/eglot-ensure-and-format)"
          ];
          init = ''
            (defun swarsel/eglot-ensure-and-format ()
                "Ensure eglot is running and enable format-on-save for current buffer."
                (eglot-ensure)
                (add-hook 'before-save-hook #'eglot-format nil 'local))

              (defalias 'start-lsp-server #'eglot)
          '';
        };
        eglot-booster = {
          config = "(eglot-booster-mode)";
          enable = true;
          package = eglot-booster;
          after = [ "eglot" ];
        };
        eldoc-box = {
          enable = true;
          after = [ "eglot" ];
          hook = [ "(eglot-managed-mode . eldoc-box-hover-at-point-mode)" ];
        };
      };
    };
}
