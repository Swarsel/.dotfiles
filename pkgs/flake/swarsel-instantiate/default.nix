{ name, writeShellApplication, ... }:
writeShellApplication {
  inherit name;
  text = ''
    nix-instantiate --strict --eval --expr "let lib = import <nixpkgs/lib>; in $*"
  '';
}
