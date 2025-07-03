{ self, name, writeShellApplication, openssh }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ openssh ];
  text = builtins.readFile "${self}/files/scripts/${name}.sh";
}
