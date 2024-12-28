{ self, writeShellApplication, git }:
let
  name = "waybarupdate";
in
writeShellApplication {
  inherit name;
  runtimeInputs = [ git ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
