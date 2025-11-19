{ name, writeShellApplication, speechd, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ speechd ];
  text = ''
    sleep "$1"; while true; do spd-say "$2"; sleep 0.5; done;
  '';
}
