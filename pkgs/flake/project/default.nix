{ name, writeShellApplication, ... }:
writeShellApplication {
  inherit name;
  text = ''
    set -euo pipefail

    if [ ! -d "$(pwd)/.git" ]; then
        git init
    fi
    nix flake init --template "$FLAKE"#"$1"
    direnv allow
  '';
}
