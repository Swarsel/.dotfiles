{ writeShellApplication, nvd }:

writeShellApplication {
  name = "update-checker";
  runtimeInputs = [ nvd ];
  text = builtins.readFile ../../scripts/update-checker.sh;
}
