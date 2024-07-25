{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{

  options.swarselsystems.startup = mkOption {
    type = types.listOf (types.attrsOf types.str);
    default = [
      { command = "nextcloud --background"; }
      { command = "discord --start-minimized"; }
      { command = "element-desktop --hidden  -enable-features=UseOzonePlatform -ozone-platform=wayland --disable-gpu-driver-bug-workarounds"; }
      { command = "ANKI_WAYLAND=1 anki"; }
      { command = "OBSIDIAN_USE_WAYLAND=1 obsidian"; }
      { command = "nm-applet"; }
    ];
  };
}
