{ lib, config, confLib, ... }:
{
  options.swarselmodules.shikane = lib.mkEnableOption "kanshi settings";
  config = lib.mkIf config.swarselmodules.shikane {

    systemd.user.services.shikane = lib.mkIf (config.swarselmodules ? optional-noctalia && config.swarselsystems.noctalia-systemd) (confLib.overrideTarget "noctalia-shell.target");
    services.shikane = {
      enable = true;
      settings =
        let
          homeMonitor = [
            "m=PHL BDM3270"
            "s=AU11806002320"
            "v=Philips Consumer Electronics Company"
          ];
          exec = [ "notify-send shikane \"Profile $SHIKANE_PROFILE_NAME has been applied\"" ];
        in
        {
          profile = [

            {
              name = "internal-on";
              inherit exec;
              output = [
                {
                  match = config.swarselsystems.sharescreen;
                  enable = true;
                  mode = "${config.swarselsystems.highResolution}@165.000";
                  scale = 1.0;
                }
              ];
            }

            {
              name = "home-internal-on";
              inherit exec;
              output = [
                {
                  match = config.swarselsystems.sharescreen;
                  enable = true;
                  scale = 1.7;
                  position = "2560,0";
                }
                {
                  match = homeMonitor;
                  enable = true;
                  scale = 1.0;
                  mode = "2560x1440";
                  position = "0,0";
                }
              ];
            }

            {
              name = "home-internal-off";
              inherit exec;
              output = [
                {
                  match = config.swarselsystems.sharescreen;
                  enable = false;
                  position = "2560,0";
                }
                {
                  match = homeMonitor;
                  scale = 1.0;
                  enable = true;
                  mode = "2560x1440";
                  position = "0,0";
                }
              ];
            }

          ];
        };
    };
  };
}
