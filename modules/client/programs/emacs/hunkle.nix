{
  flake-file.inputs.hunkle = {
    url = "github:Swarsel/hunkle";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
      treefmt-nix.follows = "treefmt-nix";
      git-hooks-nix.follows = "pre-commit-hooks";
    };
  };

  flake.modules.homeManager.emacs-init = { pkgs, inputs, ... }: {
    config.programs.emacs.init.usePackage.hunkle = {
      enable = true;
      package =
        epkgs:
        epkgs.trivialBuild {
          pname = "hunkle";
          version = "0.1.0";
          src = "${inputs.hunkle}/emacs";
          packageRequires = [ epkgs.magit ];
          postPatch = ''
            substituteInPlace hunkle.el \
              --replace-fail '(defcustom hunkle-executable "hunkle"' \
                '(defcustom hunkle-executable "${pkgs.hunkle}/bin/hunkle"'
          '';
        };
      after = [ "magit" ];
      config = "(hunkle-magit-setup)";
    };
  };
}
