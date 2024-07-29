{ writeShellApplication, emacs-pgtk, sway, jq }:

writeShellApplication {
  name = "ew";
  runtimeInputs = [ emacs-pgtk sway jq ];
  text = builtins.readFile ../../scripts/editor-wait.sh;
}
