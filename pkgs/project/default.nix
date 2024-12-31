{ self, name, writeShellApplication }:
writeShellApplication {
  inherit name;
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
