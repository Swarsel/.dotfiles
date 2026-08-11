{
  flake.modules.homeManager.kanshi =
    {
      root,
      config,
      pkgs,
      confLib,
      ...
    }:
    {
      config = {
        swarselsystems = {
          enabledHomeModules = [ "kanshi" ];
          monitors.homedesktop = rec {
            mode = "2560x1440";
            model = "PHL BDM3270";
            name = "${vendor} ${model} ${serial}";
            output = name;
            position = "0,0";
            scale = "1";
            serial = "AU11806002320";
            vendor = "Philips Consumer Electronics Company";
            workspace = "11:M";
          };
        };
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
              output = confLib.mkKanshiOutput config.swarselsystems.monitors.homedesktop { };
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
                  monitor = config.swarselsystems.monitors.homedesktop;
                in
                {
                  exec = [
                    "${pkgs.swaybg}/bin/swaybg --output '${config.swarselsystems.sharescreen}' --image ${config.swarselsystems.wallpaper} --mode ${config.stylix.imageScalingMode}"
                    "${pkgs.swaybg}/bin/swaybg --output '${monitor.name}' --image ${root "files/wallpaper/landscape/standwp.png"} --mode ${config.stylix.imageScalingMode}"
                  ];
                  name = "lidopen";
                  outputs = [
                    {
                      criteria = config.swarselsystems.sharescreen;
                      position = "2560,0";
                      scale = 1.7;
                      status = "enable";
                    }
                    (confLib.mkKanshiOutput monitor { })
                  ];
                };
            }
            {
              profile =
                let
                  monitor = config.swarselsystems.monitors.homedesktop;
                in
                {
                  exec = [
                    "${pkgs.swaybg}/bin/swaybg --output '${monitor.name}' --image ${root "files/wallpaper/landscape/standwp.png"} --mode ${config.stylix.imageScalingMode}"
                  ];
                  name = "lidclosed";
                  outputs = [
                    {
                      criteria = config.swarselsystems.sharescreen;
                      position = "2560,0";
                      status = "disable";
                    }
                    (confLib.mkKanshiOutput monitor { })
                  ];
                };
            }
          ];
        };
        systemd.user.services.kanshi = confLib.overrideTarget "sway-session.target";
      };
    };
}
