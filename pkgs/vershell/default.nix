{ writeShellApplication }:

writeShellApplication {
  name = "vershell";
  runtimeInputs = [ ];
  text = ''
    nix shell github:nixos/nixpkgs/"$1"#"$2";
  '';
}
