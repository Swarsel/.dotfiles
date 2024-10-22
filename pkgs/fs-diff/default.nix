{ writeShellApplication }:

writeShellApplication {
  name = "fs-diff";
  text = builtins.readFile ../../scripts/fs-diff.sh;
}
