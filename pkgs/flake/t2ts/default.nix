{ name, writeShellApplication, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ ];
  text = ''
    date -d"$1" +%s
  '';
}
