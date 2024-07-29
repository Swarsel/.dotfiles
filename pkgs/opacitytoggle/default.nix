{ writeShellApplication, sway }:

writeShellApplication {
  name = "opacitytoggle";
  runtimeInputs = [ sway ];
  text = builtins.readFile ../../scripts/opacitytoggle.sh;
}
