{
  name,
  busybox,
  noctalia,
  wl-mirror,
  wlr-randr,
  writeShellApplication,
  ...
}:

writeShellApplication {
  inherit name;
  runtimeInputs = [
    busybox
    noctalia
    wl-mirror
    wlr-randr
  ];
  text = ''
    if pgrep wl-mirror >/dev/null; then
      exit 0
    fi
    target=$(wlr-randr | grep "$2" | cut -d" " -f1)
    setsid sh -c "
      noctalia msg notification-dnd-set on
      wl-present mirror '$1' --fullscreen-output '$target'
      noctalia msg notification-dnd-set off
    " >/dev/null 2>&1 &
  '';
}
