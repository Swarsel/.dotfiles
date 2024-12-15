{ writeShellApplication }:

writeShellApplication {
  name = "t2ts";
  runtimeInputs = [ ];
  text = ''
    date -d"$1" +%s
  '';
}
