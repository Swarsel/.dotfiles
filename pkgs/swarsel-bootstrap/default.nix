{ self, writeShellApplication, openssh }:
let
  name = "swarsel-bootstrap";
in
writeShellApplication {
  inherit name;
  runtimeInputs = [ openssh ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
