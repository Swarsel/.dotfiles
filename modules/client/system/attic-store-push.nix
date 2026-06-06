{
  flake.modules.homeManager.attic-store-push = { lib, config, pkgs, ... }: {
    config = {
      swarselsystems.enabledHomeModules = [ "attic-store-push" ];

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
          Restart = "always";
          RestartSec = 30;
        };
      };
    };
  };
}
