{ name, writeShellApplication, config, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ config.nix.package ];
  text = ''
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
  '';
}
