{ self, pkgs, ... }:
{
  # enable emacs overlay for bleeding edge features
  # also read init.el file and install use-package packages
  programs.emacs = {
    enable = true;
    package = pkgs.emacsWithPackagesFromUsePackage {
      config = self + /programs/emacs/init.el;
      package = pkgs.emacs-pgtk;
      alwaysEnsure = true;
      alwaysTangle = true;
      extraEmacsPackages = epkgs: [
        epkgs.mu4e
        epkgs.use-package
        # epkgs.lsp-bridge
        epkgs.doom-themes

        # build the rest of the packages myself
        # org-calfw is severely outdated on MELPA and throws many warnings on emacs startup
        # build the package from the haji-ali fork, which is well-maintained
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
    # socketActivation.enable = false;
    # startWithUserSession = "graphical";
  };
}
