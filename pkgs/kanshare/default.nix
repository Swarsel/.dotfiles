{ name, writeShellApplication, wlr-randr, busybox, wl-mirror, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ wlr-randr busybox wl-mirror ];
  text = ''
    wlr-randr | grep "$2" | cut -d" " -f1 | xargs -I{} wl-present mirror "$1" --fullscreen-output {}
  '';
}
