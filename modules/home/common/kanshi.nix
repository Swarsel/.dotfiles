{ self, lib, pkgs, config, confLib, ... }:
{
  options.swarselmodules.kanshi = lib.mkEnableOption "kanshi settings";
  config = lib.mkIf config.swarselmodules.kanshi {
    swarselsystems = {
      monitors = {
        homedesktop = rec {
          name = "Philips Consumer Electronics Company PHL BDM3270 AU11806002320";
          mode = "2560x1440";
          scale = "1";
          position = "0,0";
          workspace = "11:M";
          output = name;
        };
      };
    };

    systemd.user.services.kanshi = confLib.overrideTarget "sway-session.target";
    services.kanshi = {
      enable = true;
      settings = [
        {
          # laptop screen
          output = {
            criteria = config.swarselsystems.sharescreen;
            mode = config.swarselsystems.highResolution;
            scale = 1.0;
          };
        }
        {
          # home main screen
          output = {
            criteria = "Philips Consumer Electronics Company PHL BDM3270 AU11806002320";
            scale = 1.0;
            mode = "2560x1440";
          };
        }
        {
          profile = {
            name = "lidopen";
            exec = [ "${pkgs.swaybg}/bin/swaybg --output '${config.swarselsystems.sharescreen}' --image ${config.swarselsystems.wallpaper} --mode ${config.stylix.imageScalingMode}" ];
            outputs = [
              {
                criteria = config.swarselsystems.sharescreen;
                status = "enable";
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
              name = "lidopen";
              exec = [
                "${pkgs.swaybg}/bin/swaybg --output '${config.swarselsystems.sharescreen}' --image ${config.swarselsystems.wallpaper} --mode ${config.stylix.imageScalingMode}"
                "${pkgs.swaybg}/bin/swaybg --output '${monitor}' --image ${self}/files/wallpaper/standwp.png --mode ${config.stylix.imageScalingMode}"
              ];
              outputs = [
                {
                  criteria = config.swarselsystems.sharescreen;
                  status = "enable";
                  scale = 1.7;
                  position = "2560,0";
                }
                {
                  criteria = monitor;
                  scale = 1.0;
                  mode = "2560x1440";
                  position = "0,0";
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
              name = "lidclosed";
              exec = [ "${pkgs.swaybg}/bin/swaybg --output '${monitor}' --image ${self}/files/wallpaper/standwp.png --mode ${config.stylix.imageScalingMode}" ];
              outputs = [
                {
                  criteria = config.swarselsystems.sharescreen;
                  status = "disable";
                  position = "2560,0";
                }
                {
                  criteria = monitor;
                  scale = 1.0;
                  mode = "2560x1440";
                  position = "0,0";
                }
              ];
            };
        }
      ];
    };
  };
}
