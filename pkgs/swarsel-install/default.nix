{ writeShellApplication, git }:

writeShellApplication {
  name = "swarsel-install";
  runtimeInputs = [ git ];
  text = builtins.readFile ../../scripts/swarsel-install.sh;
}
