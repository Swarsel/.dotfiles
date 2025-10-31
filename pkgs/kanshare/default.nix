{ name, writeShellApplication, wlr-randr, busybox, wl-mirror, mako, ... }:

writeShellApplication {
  inherit name;
  runtimeInputs = [ wlr-randr busybox wl-mirror mako ];
  text = ''
    makoctl mode -a do-not-disturb
    wlr-randr | grep "$2" | cut -d" " -f1 | xargs -I{} wl-present mirror "$1" --fullscreen-output {}
    makoctl mode -r do-not-disturb
  '';
}
