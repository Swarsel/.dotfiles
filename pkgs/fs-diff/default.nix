{ self, writeShellApplication }:
let
  name = "fs-diff";
in
writeShellApplication {
  inherit name;
  text = builtins.readFile "${self}/scripts/${name}.sh";
}
