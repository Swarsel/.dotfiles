# This template is based on https://github.com/Leixb/latex-template/tree/master
{
  description = "LaTeX Flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    {

      lib.latexmk = import ./build-document.nix;

    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pname = "document";

        pkgs = import nixpkgs { inherit system; };

        latex-packages = with pkgs; [
          (texlive.combine {
            inherit (texlive)
              scheme-medium
              framed
              titlesec
              cleveref
              multirow
              wrapfig
              tabu
              threeparttable
              threeparttablex
              makecell
              environ
              biblatex
              biber
              fvextra
              upquote
              catchfile
              xstring
              csquotes
              minted
              dejavu
              comment
              footmisc
              xltabular
              ltablex
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
        devShell = pkgs.mkShell {
          buildInputs = [ latex-packages dev-packages ];
        };

        formatter = pkgs.nixpgks-fmt;

        packages = flake-utils.lib.flattenTree {
          default = import ./build-document.nix {
            inherit pkgs;
            name = pname;
            texlive = latex-packages;
            shellEscape = true;
            minted = true;
            SOURCE_DATE_EPOCH = toString self.lastModified;
          };
        };

        apps.default = flake-utils.lib.mkApp { drv = "${pkgs.texlivePackages.latexmk}"; exePath = "/bin/latexmk"; };
      }
    );
}
