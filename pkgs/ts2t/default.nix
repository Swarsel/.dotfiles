{ writeShellApplication, ... }:

writeShellApplication {
  name = "ts2t";
  runtimeInputs = [ ];
  text = ''
    date -d @"$1" 2>/dev/null || date -r "$1"
  '';
}
