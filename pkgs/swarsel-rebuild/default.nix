{ writeShellApplication, git }:

writeShellApplication {
  name = "swarsel-rebuild";
  runtimeInputs = [ git ];
  text = builtins.readFile ../../scripts/swarsel-rebuild.sh;
}
