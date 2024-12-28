{ self, writeShellApplication, sway }:
let
  name = "screenshare";
in
writeShellApplication {
  inherit name;
  runtimeInputs = [ sway ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
