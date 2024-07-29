{ writeShellApplication, emacs-pgtk, sway, jq }:

writeShellApplication {
  name = "e";
  runtimeInputs = [ emacs-pgtk sway jq ];
  text = builtins.readFile ../../scripts/e.sh;
}
