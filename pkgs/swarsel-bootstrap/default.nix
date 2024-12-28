{ self, name, writeShellApplication, openssh }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ openssh ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
