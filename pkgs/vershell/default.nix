{ name, writeShellApplication, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ ];
  text = ''
    nix shell github:nixos/nixpkgs/"$1"#"$2";
  '';
}
