{ appimageTools, fetchurl, writeScriptBin, pkgs }:


let
  cura5 = appimageTools.wrapType2 rec {
    name = "cura5";
    version = "5.4.0";
    src = fetchurl {
      url = "https://github.com/Ultimaker/Cura/releases/download/${version}/UltiMaker-Cura-${version}-linux-modern.AppImage";
      hash = "sha256-QVv7Wkfo082PH6n6rpsB79st2xK2+Np9ivBg/PYZd74=";
    };
    extraPkgs = pkgs: with pkgs; [ ];
  };
in
writeScriptBin "cura" ''
  #! ${pkgs.bash}/bin/bash
  # AppImage version of Cura loses current working directory and treats all paths relative to $HOME.
  # So we convert each of the files passed as argument to an absolute path.
  # This fixes use cases like `cd /path/to/my/files; cura mymodel.stl anothermodel.stl`.
  args=()
  for a in "$@"; do
      if [ -e "$a" ]; then
         a="$(realpath "$a")"
      fi
      args+=("$a")
  done
  exec "${cura5}/bin/cura5" "''${args[@]}"
''
