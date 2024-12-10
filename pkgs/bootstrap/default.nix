{ writeShellApplication, openssh }:

writeShellApplication {
  name = "bootstrap";
  runtimeInputs = [ openssh ];
  text = builtins.readFile ../../scripts/bootstrap.sh;
}
