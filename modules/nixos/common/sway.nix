{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.sway = lib.mkEnableOption "sway config";
  config = lib.mkIf config.swarselsystems.modules.sway {
    programs.sway = {
      enable = true;
      package = pkgs.swayfx;
      wrapperFeatures = {
        base = true;
        gtk = true;
      };

      extraSessionCommands = ''
        export XDG_SESSION_DESKTOP=sway
        export SDL_VIDEODRIVER=wayland
        export QT_QPA_PLATFORM=wayland-egl
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export QT_QPA_PLATFORM_PLUGIN_PATH="${pkgs.libsForQt5.qt5.qtbase.bin}/lib/qt-${pkgs.libsForQt5.qt5.qtbase.version}/plugins";
        export MOZ_ENABLE_WAYLAND=1
        export MOZ_DISABLE_RDD_SANDBOX=1
      '';
    };
  };
}
