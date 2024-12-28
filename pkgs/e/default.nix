{ self, name, writeShellApplication, emacs30-pgtk, sway, jq }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ emacs30-pgtk sway jq ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
