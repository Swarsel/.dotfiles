{ writeShellApplication, git }:

writeShellApplication {
  name = "waybarupdate";
  runtimeInputs = [ git ];
  text = builtins.readFile ../../scripts/waybarupdate.sh;
}
