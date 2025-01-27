{ appimageTools, fetchurl, ... }:
let
  pname = "mgba";
  version = "0.10.4";
  src = fetchurl {
    url = "https://github.com/mgba-emu/mgba/releases/download/${version}/mGBA-${version}-appimage-x64.appimage";
    hash = "sha256-rDihDfuA8DqxvCe6UeavCzpjeU+fSqUbFnyTNC2dc1I=";
  };
  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;
  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/io.mgba.mGBA.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/io.mgba.mGBA.desktop \
      --replace-fail 'Exec=mgba-qt %f' 'Exec=mgba'
    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

}
