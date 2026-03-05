{ name, writeShellApplication, libnotify, pass, wtype, ... }:
writeShellApplication {
  inherit name;
  runtimeInputs = [ libnotify pass wtype ];
  text = ''
    shopt -s nullglob globstar

    notify-send "$(env | grep -E 'WAYLAND|SWAY')"

    password="$1"

    pass show "$password" | {
        IFS= read -r pass
        printf %s "$pass"
    } | wtype -

    notify-send -u critical -a pass -t 1000 "Typed Password"
  '';
}
