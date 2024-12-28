{ self, writeShellApplication, sway }:
let
  name = "opacitytoggle";
in
writeShellApplication {
  inherit name;
  runtimeInputs = [ sway ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
