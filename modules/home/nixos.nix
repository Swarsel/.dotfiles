{ lib, config, ... }:
{
  options.swarselsystems.isNixos = lib.mkEnableOption "nixos host";
  config.swarselsystems.startup = lib.mkIf (!config.swarselsystems.isNixos) [
    {
      command = "sleep 60 && nixGL nextcloud --background";
    }
    { command = "sleep 60 && nixGL discord --start-minimized -enable-features=UseOzonePlatform -ozone-platform=wayland"; }
    { command = "sleep 60 && nixGL syncthingtray --wait"; }
    { command = "sleep 60 && ANKI_WAYLAND=1 nixGL anki"; }
    { command = "nm-applet --indicator"; }
    { command = "sleep 60 && OBSIDIAN_USE_WAYLAND=1 nixGL obsidian -enable-features=UseOzonePlatform -ozone-platform=wayland"; }
    { command = "sleep 60 && element-desktop --hidden  -enable-features=UseOzonePlatform -ozone-platform=wayland --disable-gpu-driver-bug-workarounds"; }
  ];

}
