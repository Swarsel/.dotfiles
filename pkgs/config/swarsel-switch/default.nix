{ name, writeShellApplication, config, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ config.nix.package ];
  text = ''
    sudo nix-env --switch-generation "$1" -p /nix/var/nix/profiles/system && sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
  '';
}
