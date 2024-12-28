{ writeShellApplication, openssh }:

writeShellApplication {
  name = "swarsel-bootstrap";
  runtimeInputs = [ openssh ];
  text = builtins.readFile ../../scripts/swarsel-bootstrap.sh;
}
