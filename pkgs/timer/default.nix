{ writeShellApplication, speechd }:

writeShellApplication {
  name = "timer";
  runtimeInputs = [ speechd ];
  text = ''
    sleep "$1"; while true; do spd-say "$2"; sleep 0.5; done;
  '';
}
