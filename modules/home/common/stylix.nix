{ lib, config, ... }:
{
  options.swarselmodules.stylix = lib.mkEnableOption "stylix settings";
  config = lib.mkIf config.swarselmodules.stylix {
    stylix = lib.mkIf (!config.swarselsystems.isNixos) (lib.recursiveUpdate
      {
        image = config.swarselsystems.wallpaper;
        targets = config.swarselsystems.stylixHomeTargets;
      }
      config.swarselsystems.stylix);
  };
}
