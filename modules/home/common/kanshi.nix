{ lib, config, ... }:
{
  options.swarselmodules.kanshi = lib.mkEnableOption "kanshi settings";
  config = lib.mkIf config.swarselmodules.kanshi {
    swarselsystems = {
      monitors = {
        homedesktop = {
          name = "Philips Consumer Electronics Company PHL BDM3270 AU11806002320";
          mode = "2560x1440";
          scale = "1";
          position = "0,0";
          workspace = "1:一";
          output = "DP-11";
        };
      };
    };
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
            outputs = [
              {
                criteria = "eDP-2";
                status = "enable";
                scale = 1.0;
              }
            ];
          };
        }
        {
          profile = {
            name = "lidopen";
            outputs = [
              {
                criteria = config.swarselsystems.sharescreen;
                status = "enable";
                scale = 1.7;
                position = "2560,0";
              }
              {
                criteria = "Philips Consumer Electronics Company PHL BDM3270 AU11806002320";
                scale = 1.0;
                mode = "2560x1440";
                position = "0,0";
              }
            ];
          };
        }
        {
          profile = {
            name = "lidclosed";
            outputs = [
              {
                criteria = config.swarselsystems.sharescreen;
                status = "disable";
                position = "2560,0";
              }
              {
                criteria = "Philips Consumer Electronics Company PHL BDM3270 AU11806002320";
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
