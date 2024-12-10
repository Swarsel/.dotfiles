{ writeShellApplication, emacs30-pgtk, sway, jq }:

writeShellApplication {
  name = "e";
  runtimeInputs = [ emacs30-pgtk sway jq ];
  text = builtins.readFile ../../scripts/e.sh;
}
