{ name, writeShellApplication, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ ];
  text = ''
    date -d @"$1" 2>/dev/null || date -r "$1"
  '';
}
