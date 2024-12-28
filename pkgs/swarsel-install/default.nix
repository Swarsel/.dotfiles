{ self, writeShellApplication, git }:
let
  name = "swarsel-install";
in
writeShellApplication {
  inherit name;
  runtimeInputs = [ git ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
