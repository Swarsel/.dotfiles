{ self, name, writeShellApplication, kitty }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ kitty ];
  text = builtins.readFile "${self}/files/scripts/${name}.sh";
}
