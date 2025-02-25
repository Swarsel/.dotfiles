{ lib, config, ... }:
{
  stylix = lib.recursiveUpdate
    {
      targets.grub.enable = false; # the styling makes grub more ugly
      image = config.swarselsystems.wallpaper;
    }
    config.swarselsystems.stylix;
  home-manager.users.swarsel = {
    stylix = {
      targets = {
        emacs.enable = false;
        waybar.enable = false;
      };
    };
  };
}
