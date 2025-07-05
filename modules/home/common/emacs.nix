{ self, lib, config, pkgs, ... }:
let
  inherit (config.swarselsystems) homeDir isPublic;
in
{
  options.swarselsystems.modules.emacs = lib.mkEnableOption "emacs settings";
  config = lib.mkIf config.swarselsystems.modules.emacs {
    # needed for elfeed
    sops.secrets.fever-pw = lib.mkIf (!isPublic) { path = "${homeDir}/.emacs.d/.fever"; };

    # enable emacs overlay for bleeding edge features
    # also read init.el file and install use-package packages
    programs.emacs = {
      enable = true;
      package = pkgs.emacsWithPackagesFromUsePackage {
        config = self + /files/emacs/init.el;
        package = pkgs.emacs-git-pgtk;
        alwaysEnsure = true;
        alwaysTangle = true;
        extraEmacsPackages = epkgs: [
          epkgs.mu4e
          epkgs.use-package
          epkgs.lsp-bridge
          epkgs.doom-themes
          epkgs.vterm
          epkgs.treesit-grammars.with-all-grammars

          # build the rest of the packages myself
          # org-calfw is severely outdated on MELPA and throws many warnings on emacs startup
          # build the package from the haji-ali fork, which is well-maintained

          (epkgs.trivialBuild rec {
            pname = "eglot-booster";
            version = "main-29-10-2024";

            src = pkgs.fetchFromGitHub {
              owner = "jdtsmith";
              repo = "eglot-booster";
              rev = "e6daa6bcaf4aceee29c8a5a949b43eb1b89900ed";
              hash = "sha256-PLfaXELkdX5NZcSmR1s/kgmU16ODF8bn56nfTh9g6bs=";
            };

            packageRequires = [ epkgs.jsonrpc epkgs.eglot ];
          })
          (epkgs.trivialBuild rec {
            pname = "calfw";
            version = "1.0.0-20231002";
            src = pkgs.fetchFromGitHub {
              owner = "haji-ali";
              repo = "emacs-calfw";
              rev = "bc99afee611690f85f0cd0bd33300f3385ddd3d3";
              hash = "sha256-0xMII1KJhTBgQ57tXJks0ZFYMXIanrOl9XyqVmu7a7Y=";
            };
            packageRequires = [ epkgs.howm ];
          })

          (epkgs.trivialBuild rec {
            pname = "fast-scroll";
            version = "1.0.0-20191016";
            src = pkgs.fetchFromGitHub {
              owner = "ahungry";
              repo = "fast-scroll";
              rev = "3f6ca0d5556fe9795b74714304564f2295dcfa24";
              hash = "sha256-w1wmJW7YwXyjvXJOWdN2+k+QmhXr4IflES/c2bCX3CI=";
            };
            packageRequires = [ ];
          })

        ];
      };
    };

    services.emacs = {
      enable = true;
      socketActivation.enable = false;
      startWithUserSession = "graphical";
    };
  };
}
