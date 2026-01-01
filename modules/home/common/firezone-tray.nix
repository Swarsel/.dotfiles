{ lib, config, pkgs, ... }:
{
  options.swarselmodules.firezone-tray = lib.mkEnableOption "enable firezone applet for tray";
  config = lib.mkIf config.swarselmodules.firezone-tray {

    systemd.user.services.firezone-applet = {
      Unit = {
        Description = "Firezone applet";
        Requires = [
          "tray.target"
        ];
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
        ExecStart = "${pkgs.firezone-gui-client}/bin/firezone-client-gui";
      };
    };
  };

}
