{ self, writeShellApplication, git }:
let
  name = "swarsel-rebuild";
in
writeShellApplication {
  inherit name;
  runtimeInputs = [ git ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
