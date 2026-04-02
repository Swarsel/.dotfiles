{ lib, config, pkgs, ... }:
{
  options.swarselmodules.firezone-tray = lib.mkEnableOption "enable firezone applet for tray";
  config = lib.mkIf config.swarselmodules.firezone-tray {

    systemd.user.services.firezone-applet = {
      Unit = {
        Description = "Firezone applet";
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
        ExecStart = "${pkgs.firezone-gui-client}/bin/firezone-client-gui";
      };
    };
  };

}
