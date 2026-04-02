{ lib, config, pkgs, ... }:
{
  options.swarselmodules.element-tray = lib.mkEnableOption "enable element applet for tray";
  config = lib.mkIf config.swarselmodules.element-tray {

    systemd.user.services.element-applet = {
      Unit = {
        Description = "Element applet";
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
        ExecStart = "${pkgs.element-desktop}/bin/element-desktop --hidden --enable-features=useozoneplatform --ozone-platform=wayland --disable-gpu-driver-bug-workarounds";
      };
    };
  };

}
