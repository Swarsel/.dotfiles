{
  flake-file.inputs.hunkle = {
    inputs = {
      flake-parts.follows = "flake-parts";
      git-hooks-nix.follows = "pre-commit-hooks";
      nixpkgs.follows = "nixpkgs";
      treefmt-nix.follows = "treefmt-nix";
    };
    url = "github:Swarsel/hunkle";
  };

  flake.modules.homeManager.emacs-init = { inputs, pkgs, ... }: {
    config.programs.emacs.init.usePackage.hunkle = {
      config = "(hunkle-magit-setup)";
      enable = true;
      package =
        epkgs:
        epkgs.trivialBuild {
          packageRequires = [ epkgs.magit ];
          pname = "hunkle";
          postPatch = ''
            substituteInPlace hunkle.el \
              --replace-fail '(defcustom hunkle-executable "hunkle"' \
                '(defcustom hunkle-executable "${pkgs.hunkle}/bin/hunkle"'
          '';
          src = "${inputs.hunkle}/emacs";
          version = "0.1.0";
        };
      after = [ "magit" ];
    };
  };
}
