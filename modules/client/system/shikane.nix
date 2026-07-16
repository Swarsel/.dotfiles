{
  flake.modules.homeManager.shikane =
    {
      config,
      lib,
      confLib,
      ...
    }:
    {
      config = {
        swarselsystems.enabledHomeModules = [ "shikane" ];
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
                  inherit exec;
                  name = "internal-on";
                  output = [
                    {
                      enable = true;
                      match = config.swarselsystems.sharescreen;
                      mode = "${config.swarselsystems.highResolution}@165.000";
                      scale = 1.0;
                    }
                  ];
                }

                {
                  inherit exec;
                  name = "home-internal-on";
                  output = [
                    {
                      enable = true;
                      match = config.swarselsystems.sharescreen;
                      position = "2560,0";
                      scale = 1.7;
                    }
                    {
                      enable = true;
                      match = homeMonitor;
                      mode = "2560x1440";
                      position = "0,0";
                      scale = 1.0;
                    }
                  ];
                }

                {
                  inherit exec;
                  name = "home-internal-off";
                  output = [
                    {
                      enable = false;
                      match = config.swarselsystems.sharescreen;
                      position = "2560,0";
                    }
                    {
                      enable = true;
                      match = homeMonitor;
                      mode = "2560x1440";
                      position = "0,0";
                      scale = 1.0;
                    }
                  ];
                }

              ];
            };
        };
        systemd.user.services.shikane = lib.mkIf (
          builtins.elem "optional-noctalia" config.swarselsystems.enabledHomeModules
          && config.swarselsystems.noctalia-systemd
        ) (confLib.overrideTarget "noctalia-shell.target");
      };
    };
}
