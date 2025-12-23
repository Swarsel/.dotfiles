{ name, writeShellApplication, nixosConfig, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ nixosConfig.nix.package ];
  text = ''
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
  '';
}
