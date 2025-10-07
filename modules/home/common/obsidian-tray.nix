{ lib, config, pkgs, ... }:
{
  options.swarselmodules.obsidian-tray = lib.mkEnableOption "enable obsidian applet for tray";
  config = lib.mkIf config.swarselmodules.obsidian-tray {

    systemd.user.services.obsidian-applet = {
      Unit = {
        Description = "Obsidian applet";
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
        ExecStart = "${pkgs.obsidian}/bin/obsidian";
      };
    };
  };

}
