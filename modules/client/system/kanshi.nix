{
  flake.modules.homeManager.kanshi =
    {
      self,
      config,
      pkgs,
      confLib,
      ...
    }:
    {
      config = {
        swarselsystems = {
          monitors = {
            homedesktop = rec {
              mode = "2560x1440";
              name = "Philips Consumer Electronics Company PHL BDM3270 AU11806002320";
              output = name;
              position = "0,0";
              scale = "1";
              workspace = "11:M";
            };
          };
        };
        swarselsystems.enabledHomeModules = [ "kanshi" ];
        services.kanshi = {
          enable = true;
          settings = [
            {
              # laptop screen
              output = {
                criteria = config.swarselsystems.sharescreen;
                mode = "${config.swarselsystems.highResolution}@165.000";
                scale = 1.0;
              };
            }
            {
              # home main screen
              output = {
                criteria = "Philips Consumer Electronics Company PHL BDM3270 AU11806002320";
                mode = "2560x1440";
                scale = 1.0;
              };
            }
            {
              profile = {
                exec = [
                  "${pkgs.swaybg}/bin/swaybg --output '${config.swarselsystems.sharescreen}' --image ${config.swarselsystems.wallpaper} --mode ${config.stylix.imageScalingMode}"
                ];
                name = "lidopen";
                outputs = [
                  {
                    criteria = config.swarselsystems.sharescreen;
                    scale = 1.0;
                    status = "enable";
                  }
                ];
              };
            }
            {
              profile =
                let
                  monitor = "Philips Consumer Electronics Company PHL BDM3270 AU11806002320";
                in
                {
                  exec = [
                    "${pkgs.swaybg}/bin/swaybg --output '${config.swarselsystems.sharescreen}' --image ${config.swarselsystems.wallpaper} --mode ${config.stylix.imageScalingMode}"
                    "${pkgs.swaybg}/bin/swaybg --output '${monitor}' --image ${self}/files/wallpaper/landscape/standwp.png --mode ${config.stylix.imageScalingMode}"
                  ];
                  name = "lidopen";
                  outputs = [
                    {
                      criteria = config.swarselsystems.sharescreen;
                      position = "2560,0";
                      scale = 1.7;
                      status = "enable";
                    }
                    {
                      criteria = monitor;
                      mode = "2560x1440";
                      position = "0,0";
                      scale = 1.0;
                    }
                  ];
                };
            }
            {
              profile =
                let
                  monitor = "Philips Consumer Electronics Company PHL BDM3270 AU11806002320";
                in
                {
                  exec = [
                    "${pkgs.swaybg}/bin/swaybg --output '${monitor}' --image ${self}/files/wallpaper/landscape/standwp.png --mode ${config.stylix.imageScalingMode}"
                  ];
                  name = "lidclosed";
                  outputs = [
                    {
                      criteria = config.swarselsystems.sharescreen;
                      position = "2560,0";
                      status = "disable";
                    }
                    {
                      criteria = monitor;
                      mode = "2560x1440";
                      position = "0,0";
                      scale = 1.0;
                    }
                  ];
                };
            }
          ];
        };
        systemd.user.services.kanshi = confLib.overrideTarget "sway-session.target";
      };
    };
}
