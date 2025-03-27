{ lib, config, ... }:
{
  stylix = lib.mkIf (!config.swarselsystems.isNixos) (lib.recursiveUpdate
    {
      image = config.swarselsystems.wallpaper;
      targets = config.swarselsystems.stylixHomeTargets;
    }
    config.swarselsystems.stylix);
}
