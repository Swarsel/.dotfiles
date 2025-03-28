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
      targets = {
        emacs.enable = false;
        waybar.enable = false;
        sway.useWallpaper = false;
        firefox.profileNames = [ "default" ];
      };
    };
  };
}
