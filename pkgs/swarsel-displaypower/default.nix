{ self, name, writeShellApplication, sway }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ sway ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
