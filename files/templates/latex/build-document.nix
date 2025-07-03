# Build a reproducible latex document with latexmk, based on:
# https://flyx.org/nix-flakes-latex/

{ pkgs
  # Document source
, src ? ./.

  # Name of the final pdf file
, name ? "document.pdf"

  # Use -shell-escape
, shellEscape ? false

  # Use minted (requires shellEscape)
, minted ? false

  # Additional flags for latexmk
, extraFlags ? [ ]

  # Do not use the default latexmk flags. Usefull if you have a .latexmkrc or you
  # don't want to use lualatex
, dontUseDefaultFlags ? false

  # texlive packages needed to build the document
  # you can also include other packages as a list.
, texlive ? pkgs.texlive.combined.scheme-full

  # Pygments package to use (needed for minted)
, pygments ? pkgs.python39Packages.pygments

  # Add system fonts
  # you can specify one font directly with: pkgs.fira-code
  # of join multiple fonts using symlinJoin:
  #   pkgs.symlinkJoin { name = "fonts"; paths = with pkgs; [ fira-code souce-code-pro ]; }
, fonts ? null

  # Date for the document in unix time. You can change it
  # to "$(date -r . +%s)" , "$(date -d "2022/02/22" +%s)", toString
  # self.lastModified
, SOURCE_DATE_EPOCH ? "$(git log -1 --pretty=%ct)"
}:

let
  inherit (pkgs) lib;
  defaultFlags = [
    "-interaction=nonstopmode"
    "-pdf"
    "-lualatex"
    "-pretex='\\pdfvariable suppressoptionalinfo 512\\relax'"
    "-usepretex"
  ];
  flags = lib.concatLists [
    (lib.optional (!dontUseDefaultFlags) defaultFlags)
    extraFlags
    (lib.optional shellEscape [ "-shell-escape" ])
  ];
in

assert minted -> shellEscape;

pkgs.stdenvNoCC.mkDerivation rec {
  inherit src name;

  buildInputs = [ texlive pkgs.git ] ++
    lib.optional minted [ pkgs.which pygments ];

  TEXMFHOME = "./cache";
  TEXMFVAR = "./cache/var";

  OSFONTDIR = lib.optionalString (fonts != null) "${fonts}/share/fonts";

  buildPhase = ''
    runHook preBuild

    SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH}" latexmk ${toString flags}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -m644 -D *.pdf $out/${name}

    runHook postInstall
  '';
}
