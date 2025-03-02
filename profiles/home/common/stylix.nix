{ lib, config, ... }:
{
  stylix = lib.mkIf (!config.swarselsystems.isNixos) (lib.recursiveUpdate
    {
      image = config.swarselsystems.wallpaper;
      targets = {
        emacs.enable = false;
        waybar.enable = false;
      };
    }
    config.swarselsystems.stylix);
}
