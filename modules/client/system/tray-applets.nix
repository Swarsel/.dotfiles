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
          description = "Anki applet";
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
        element = {
          description = "Element applet";
          execStart = "${pkgs.element-desktop}/bin/element-desktop --hidden --enable-features=useozoneplatform --ozone-platform=wayland --disable-gpu-driver-bug-workarounds";
        };
        firezone = {
          description = "Firezone applet";
          execStart = "${pkgs.firezone-gui-client}/bin/firezone-client-gui";
        };
        obsidian = {
          description = "Obsidian applet";
          execStart = "${lib.getExe config.programs.obsidian.package}";
        };
        vesktop = {
          description = "Vesktop applet";
          execStart = "${pkgs.vesktop}/bin/vesktop --start-minimized --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime";
        };
      };
      cfg = config.swarselsystems.trayApplets;
      enabledApplets = lib.filterAttrs (n: _: cfg.${n}.enable) applets;
    in
    {
      options.swarselsystems.trayApplets = lib.mapAttrs (_: _: {
        enable = lib.swarselsystems.mkTrueOption;
      }) applets;
      config = {
        swarselsystems.enabledHomeModules = lib.mapAttrsToList (n: _: "${n}-tray") enabledApplets;

        systemd.user.services = lib.mapAttrs' (
          n: appletDef: lib.nameValuePair "${n}-applet" (confLib.mkTrayApplet appletDef)
        ) enabledApplets;
      };
    };
}
