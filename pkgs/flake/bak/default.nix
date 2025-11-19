{ name, writeShellApplication, ... }:

writeShellApplication {
  inherit name;
  text = ''
    cp -r "$1"{,.bak}
  '';
}
