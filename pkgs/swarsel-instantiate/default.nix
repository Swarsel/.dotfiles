{ name, writeShellApplication, ... }:
writeShellApplication {
  inherit name;
  text = ''
    set -euo pipefail
    nix-instantiate --strict --eval --expr "let lib = import <nixpkgs/lib>; in $*"
  '';
}
