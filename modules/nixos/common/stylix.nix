{ lib, config, ... }:
{
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
}
