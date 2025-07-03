{ lib, config, ... }:
{
  options.swarselsystems.modules.stylix = lib.mkEnableOption "stylix config";
  config = lib.mkIf config.swarselsystems.modules.stylix {
    stylix = lib.recursiveUpdate
      {
        targets.grub.enable = false; # the styling makes grub more ugly
        image = config.swarselsystems.wallpaper;
      }
      config.swarselsystems.stylix;
    home-manager.users."${config.swarselsystems.mainUser}" = {
      stylix = {
        targets = config.swarselsystems.stylixHomeTargets;
      };
    };
  };
}
