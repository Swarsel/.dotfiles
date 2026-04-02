{ lib, config, pkgs, ... }:
{
  options.swarselmodules.vesktop-tray = lib.mkEnableOption "enable vesktop applet for tray";
  config = lib.mkIf config.swarselmodules.vesktop-tray {

    systemd.user.services.vesktop-applet = {
      Unit = {
        Description = "Vesktop applet";
        Requires = [ "graphical-session.target" ];
        After = [
          "graphical-session.target"
          "tray.target"
        ];
        PartOf = [
          "tray.target"
        ];
      };

      Install = {
        WantedBy = [ "tray.target" ];
      };

      Service = {
        ExecStart = "${pkgs.vesktop}/bin/vesktop --start-minimized --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime";
      };
    };
  };

}
