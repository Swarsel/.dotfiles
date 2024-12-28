{ self, writeShellApplication, emacs30-pgtk, sway, jq }:
let
  name = "e";
in
writeShellApplication {
  inherit name;
  runtimeInputs = [ emacs30-pgtk sway jq ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
