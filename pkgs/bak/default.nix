{ writeShellApplication, ... }:

writeShellApplication {
  name = "bak";
  text = ''
    cp -r "$1"{,.bak}
  '';
}
