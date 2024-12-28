{ self, writeShellApplication, nvd }:
let
  name = "update-checker";
in
writeShellApplication {
  inherit name;
  runtimeInputs = [ nvd ];
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
