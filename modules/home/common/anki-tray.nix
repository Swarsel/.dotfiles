{ lib, config, ... }:
{
  options.swarselmodules.anki-tray = lib.mkEnableOption "enable anki applet for tray";
  config = lib.mkIf config.swarselmodules.anki-tray {

    systemd.user.services.anki-applet = {
      Unit = {
        Description = "Anki applet";
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
        # ExecStart = "${lib.getExe config.programs.anki.package}";
        Type = "simple";
        ExecStart = "/etc/profiles/per-user/${config.swarselsystems.mainUser}/bin/anki";
        Environment = [
          "QT_QPA_PLATFORM=xcb"
        ];
        TimeoutStopSec = "2s";
        KillMode = "mixed";
        KillSignal = "SIGTERM";
        SendSIGKILL = "yes";
      };
    };

  };
}
