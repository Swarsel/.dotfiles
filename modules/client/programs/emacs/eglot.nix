{
  flake.modules.homeManager.emacs-init = { pkgs, ... }:
    let
      eglot-booster = epkgs: epkgs.trivialBuild rec {
        pname = "eglot-booster";
        version = "main-29-10-2024";
        src = pkgs.fetchFromGitHub {
          owner = "jdtsmith";
          repo = "eglot-booster";
          rev = "e6daa6bcaf4aceee29c8a5a949b43eb1b89900ed";
          hash = "sha256-PLfaXELkdX5NZcSmR1s/kgmU16ODF8bn56nfTh9g6bs=";
        };
        packageRequires = [ epkgs.jsonrpc epkgs.eglot ];
      };
    in
    {
      config.programs.emacs.init.usePackage = {
        eglot = {
          enable = true;
          hook = [ "((python-mode python-ts-mode c-mode c-ts-mode c++-mode c++-ts-mode go-mode go-ts-mode tex-mode LaTeX-mode) . swarsel/eglot-ensure-and-format)" ];
          init = ''
            (defun swarsel/eglot-ensure-and-format ()
                "Ensure eglot is running and enable format-on-save for current buffer."
                (eglot-ensure)
                (add-hook 'before-save-hook #'eglot-format nil 'local))

              (defalias 'start-lsp-server #'eglot)
          '';
          custom = {
            eldoc-echo-area-use-multiline-p = false;
            eldoc-echo-area-prefer-doc-buffer = true;
            eglot-events-buffer-size = 0;
            eglot-sync-connect = false;
            eglot-connect-timeout = false;
            eglot-autoshutdown = true;
            eglot-send-changes-idle-time = 3;
            flymake-no-changes-timeout = 5;
          };
          config = "(fset #'jsonrpc--log-event #'ignore)";
          bindLocal.eglot-mode-map = {
            "M-(" = "flymake-goto-next-error";
            "C-c ," = "eglot-code-actions";
          };
        };

        eldoc-box = {
          enable = true;
          after = [ "eglot" ];
          hook = [ "(eglot-managed-mode . eldoc-box-hover-at-point-mode)" ];
        };

        eglot-booster = {
          enable = true;
          package = eglot-booster;
          after = [ "eglot" ];
          config = "(eglot-booster-mode)";
        };
      };
    };
}
