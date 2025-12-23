{ lib, config, pkgs, ... }:
{
  options.swarselmodules.attic-store-push = lib.mkEnableOption "enable automatic attic store push";
  config = lib.mkIf config.swarselmodules.attic-store-push {

    systemd.user.services.attic-store-push = {
      Unit = {
        Description = "Attic store pusher";
        Requires = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${lib.getExe pkgs.attic-client} watch-store ${config.swarselsystems.mainUser}:${config.swarselsystems.mainUser}";
      };
    };
  };

}
