{
  flake.modules.homeManager.mako = { lib, ... }: {
    config = {
      swarselsystems.enabledHomeModules = [ "mako" ];
      services.mako = {
        enable = true;
        settings = {
          border-radius = 15;
          border-size = 1;
          "category=mpd" = {
            default-timeout = 2000;
            group-by = "category";
          };
          default-timeout = 5000;
          height = 150;
          icons = 1;
          ignore-timeout = false;
          layer = "overlay";
          "mode=do-not-disturb" = {
            invisible = true;
          };
          sort = "-time";
          "urgency=high" = {
            border-color = lib.mkForce "#bf616a";
            default-timeout = 3000;
          };
          "urgency=low" = {
            border-color = lib.mkForce "#cccccc";
          };
          "urgency=normal" = {
            border-color = lib.mkForce "#d08770";
          };
          width = 300;
        };
      };
    };
  };
}
