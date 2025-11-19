{ self, name, writeShellApplication, sway }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ sway ];
  text = builtins.readFile "${self}/files/scripts/${name}.sh";
}
