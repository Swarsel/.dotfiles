{ name, writeShellApplication, sway, ... }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ sway ];
  text = ''
    swaymsg "output * power on" > /dev/null 2>&1 || true
    swaymsg "output * dpms on" > /dev/null 2>&1 || true
  '';
}
