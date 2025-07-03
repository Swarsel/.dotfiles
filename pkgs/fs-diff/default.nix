{ self, name, writeShellApplication }:
writeShellApplication {
  inherit name;
  text = builtins.readFile "${self}/files/scripts/${name}.sh";
}
