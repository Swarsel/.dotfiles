{ writeShellApplication, sway }:

writeShellApplication {
  name = "screenshare";
  runtimeInputs = [ sway ];
  text = builtins.readFile ../../scripts/screenshare.sh;
}
