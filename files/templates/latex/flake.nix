# This template is based on https://github.com/Leixb/latex-template/tree/master
{
  description = "LaTeX Flake";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
    }:
    {

      lib.latexmk = import ./build-document.nix;

    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pname = "document";

        pkgs = import nixpkgs { inherit system; };

        latex-packages = with pkgs; [
          (texlive.combine {
            inherit (texlive)
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
              ltablex
              makecell
              minted
              multirow
              scheme-medium
              tabu
              threeparttable
              threeparttablex
              titlesec
              upquote
              wrapfig
              xltabular
              xstring
              ;
          })
          which
          python39Packages.pygments
        ];

        dev-packages = with pkgs; [
          texlab
          zathura
          wmctrl
        ];
      in
      rec {
        apps.default = flake-utils.lib.mkApp {
          drv = "${pkgs.texlivePackages.latexmk}";
          exePath = "/bin/latexmk";
        };
        devShell = pkgs.mkShell {
          buildInputs = [
            latex-packages
            dev-packages
          ];
        };
        formatter = pkgs.nixfmt;
        packages = flake-utils.lib.flattenTree {
          default = import ./build-document.nix {
            inherit pkgs;
            SOURCE_DATE_EPOCH = toString self.lastModified;
            minted = true;
            name = pname;
            shellEscape = true;
            texlive = latex-packages;
          };
        };
      }
    );
}
