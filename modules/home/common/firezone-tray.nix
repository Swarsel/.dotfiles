{ pkgs, ... }:
{
  config = {
    swarselsystems.enabledHomeModules = [ "firezone-tray" ];

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
