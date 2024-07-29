{ writeShellApplication }:

writeShellApplication {
  name = "bak";
  text = ''
    cp "$1"{,.bak}
  '';
}
