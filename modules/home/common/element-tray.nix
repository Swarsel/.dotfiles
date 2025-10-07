{ lib, config, pkgs, ... }:
{
  options.swarselmodules.element-tray = lib.mkEnableOption "enable element applet for tray";
  config = lib.mkIf config.swarselmodules.element-tray {

    systemd.user.services.element-applet = {
      Unit = {
        Description = "Element applet";
        Requires = [ "tray.target" ];
        After = [
          "graphical-session.target"
          "tray.target"
        ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.element-desktop}/bin/element-desktop --hidden --enable-features=useozoneplatform --ozone-platform=wayland --disable-gpu-driver-bug-workarounds";
      };
    };
  };

}
