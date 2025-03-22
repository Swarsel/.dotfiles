{ name, writeShellApplication, sway, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ sway ];
  text = ''
    swaymsg '[app_id=at.yrlf.wl_mirror] move to workspace 14:T'
    swaymsg '[app_id=at.yrlf.wl_mirror] fullscreen'
  '';
}
