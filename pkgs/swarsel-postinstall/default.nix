{ self, name, writeShellApplication, git }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ git ];
  text = builtins.readFile "${self}/files/scripts/${name}.sh";
}
