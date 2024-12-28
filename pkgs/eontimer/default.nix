{ pkgs, python3Packages, ... }:

python3Packages.buildPythonApplication rec {
  pname = "eontimer";
  version = "3.0.0";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "DasAmpharos";
    repo = "EonTimer";
    rev = "9449e6158f0aa6eaa24b3b1d0a427aa198b5c0e4";
    hash = "sha256-+XN/VGGlEg2gVncRZrWDOZ2bfxt8xyIu22F2wHlG6YI=";
  };

  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
    altgraph
    certifi
    charset-normalizer
    idna
    libsass
    macholib
    packaging
    pillow
    pipdeptree
    platformdirs
    pyinstaller
    pyinstaller-hooks-contrib
    pyside6
    requests
    setuptools
    shiboken6
    urllib3
  ];

  buildPhase = ''
    ${pkgs.python3Packages.pyinstaller}/bin/pyinstaller EonTimer.spec
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp dist/EonTimer $out/bin/
  '';


}
