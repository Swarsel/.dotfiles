{ lib, config, ... }:
{
  options.swarselmodules.obsidian-tray = lib.mkEnableOption "enable obsidian applet for tray";
  config = lib.mkIf config.swarselmodules.obsidian-tray {

    systemd.user.services.obsidian-applet = {
      Unit = {
        Description = "Obsidian applet";
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
        ExecStart = "${lib.getExe config.programs.obsidian.package}";
      };
    };
  };

}
