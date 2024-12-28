{ writeShellApplication, git }:

writeShellApplication {
  name = "swarsel-postinstall";
  runtimeInputs = [ git ];
  text = builtins.readFile ../../scripts/swarsel-postinstall.sh;
}
