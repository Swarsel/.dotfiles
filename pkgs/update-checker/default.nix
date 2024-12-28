{ self, name, writeShellApplication, nvd }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ nvd ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
