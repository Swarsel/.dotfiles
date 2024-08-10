{ writeShellApplication, sway }:

writeShellApplication {
  name = "update-checker";
  text = builtins.readFile ../../scripts/update-checker.sh;
}
