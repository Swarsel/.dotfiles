{ lib, config, pkgs, ... }:
{
  options.swarselmodules.vesktop-tray = lib.mkEnableOption "enable vesktop applet for tray";
  config = lib.mkIf config.swarselmodules.vesktop-tray {

    systemd.user.services.vesktop-applet = {
      Unit = {
        Description = "Vesktop applet";
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
        ExecStart = "${pkgs.vesktop}/bin/vesktop --start-minimized --enable-speech-dispatcher --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime";
      };
    };
  };

}
