{
  flake.modules.homeManager.tray-applets =
    {
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    let
      applets = {
        anki = {
          execStart = "/etc/profiles/per-user/${config.swarselsystems.mainUser}/bin/anki";
          extraService = {
            Environment = [ "QT_QPA_PLATFORM=xcb" ];
            KillMode = "mixed";
            KillSignal = "SIGTERM";
            SendSIGKILL = "yes";
            TimeoutStopSec = "2s";
            Type = "simple";
          };
        };
        element.execStart = "${pkgs.element-desktop}/bin/element-desktop --hidden --enable-features=useozoneplatform --ozone-platform=wayland --disable-gpu-driver-bug-workarounds";
        firezone.execStart = "${pkgs.firezone-gui-client}/bin/firezone-client-gui";
        obsidian.execStart = "${lib.getExe config.programs.obsidian.package}";
        vesktop.execStart = "${pkgs.vesktop}/bin/vesktop --start-minimized --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime";
      };
      enabledApplets = lib.filterAttrs (n: _: config.swarselsystems.trayApplets.${n}.enable) applets;
    in
    {
      options.swarselsystems.trayApplets = lib.mapAttrs (_: _: {
        enable = lib.swarselsystems.mkTrueOption;
      }) applets;
      config = {
        swarselsystems.enabledHomeModules = lib.mapAttrsToList (n: _: "${n}-tray") enabledApplets;

        systemd.user.services = lib.mapAttrs' (
          n: appletDef:
          lib.nameValuePair "${n}-applet" (
            confLib.mkTrayApplet (
              appletDef // { description = "${lib.swarselsystems.toCapitalized n} applet"; }
            )
          )
        ) enabledApplets;
      };
    };
}
