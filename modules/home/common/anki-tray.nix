{ lib, config, pkgs, ... }:
{
  options.swarselmodules.anki-tray = lib.mkEnableOption "enable anki applet for tray";
  config = lib.mkIf config.swarselmodules.anki-tray {

    systemd.user.services.anki-applet = {
      Unit = {
        Description = "Anki applet";
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
        ExecStart = "${pkgs.anki-bin}/bin/anki-bin";
      };
    };

  };
}
