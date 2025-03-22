{ lib, config, ... }:
{
  options.swarselsystems = {
    isNixos = lib.mkEnableOption "nixos host";
    isPublic = lib.mkEnableOption "is a public machine (no secrets)";
    swayfxConfig = lib.mkOption {
      type = lib.types.str;
      default = "
              blur enable
              blur_xray disable
              blur_passes 1
              blur_radius 1
              shadows enable
              corner_radius 2
              titlebar_separator disable
              default_dim_inactive 0.02
          ";
      internal = true;
    };
  };

  config.swarselsystems = {
    startup = lib.mkIf (!config.swarselsystems.isNixos) [
      { command = "sleep 60 && nixGL nextcloud --background"; }
      { command = "sleep 60 && nixGL vesktop --start-minimized -enable-features=UseOzonePlatform -ozone-platform=wayland"; }
      { command = "sleep 60 && nixGL syncthingtray --wait"; }
      { command = "sleep 60 && ANKI_WAYLAND=1 nixGL anki"; }
      { command = "nm-applet --indicator"; }
      { command = "sleep 60 && OBSIDIAN_USE_WAYLAND=1 nixGL obsidian -enable-features=UseOzonePlatform -ozone-platform=wayland"; }
      { command = "sleep 60 && element-desktop --hidden  -enable-features=UseOzonePlatform -ozone-platform=wayland --disable-gpu-driver-bug-workarounds"; }
    ];
    swayfxConfig = lib.mkIf (!config.swarselsystems.isNixos) " ";
  };
}
