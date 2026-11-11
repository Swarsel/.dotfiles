{
  description = "name";

  inputs = {
    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs";
      url = "github:hercules-ci/flake-parts";
    };

    git-hooks-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/git-hooks.nix";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    pedantix = {
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "git-hooks-nix";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
      url = "github:Swarsel/pedantix";
    };

    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.git-hooks-nix.flakeModule
        inputs.pedantix.flakeModules.default
        inputs.treefmt-nix.flakeModule
      ];
      perSystem =
        {
          config,
          pkgs,
          self',
          ...
        }:
        {
          devShells.default = pkgs.mkShell {
            inputsFrom = [
              self'.packages.default
              config.treefmt.build.devShell
            ];
            packages = [ pkgs.texlab ];
            shellHook = config.pre-commit.installationScript;
          };
          packages.default = pkgs.stdenvNoCC.mkDerivation {
            buildPhase = ''
              runHook preBuild
              export TEXMFHOME=$PWD/.cache TEXMFVAR=$PWD/.cache/var
              latexmk -interaction=nonstopmode -pretex='\pdfvariable suppressoptionalinfo 512\relax' -usepretex
              runHook postBuild
            '';
            env.SOURCE_DATE_EPOCH = toString inputs.self.lastModified;
            installPhase = ''
              install -Dm644 main.pdf $out
            '';
            name = "document.pdf";
            nativeBuildInputs = [
              pkgs.python3Packages.pygments
              (pkgs.texliveMedium.withPackages (
                ps: with ps; [
                  biber
                  biblatex
                  catchfile
                  cleveref
                  comment
                  csquotes
                  dejavu
                  environ
                  footmisc
                  framed
                  fvextra
                  latexmk
                  ltablex
                  makecell
                  minted
                  multirow
                  tabu
                  threeparttable
                  threeparttablex
                  titlesec
                  upquote
                  wrapfig
                  xltabular
                  xstring
                ]
              ))
            ];
            src = ./.;
          };
          pre-commit.settings.hooks = {
            deadnix.enable = true;
            statix.enable = true;
            treefmt.enable = true;
          };
          treefmt.programs.pedantix.enable = true;
        };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
}
