{ self, name, writeShellApplication, jq }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ jq ];
  text = builtins.readFile "${self}/files/scripts/${name}.sh";
}
