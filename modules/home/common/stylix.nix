{ lib, config, ... }:
{
  options.swarselsystems.modules.stylix = lib.mkEnableOption "stylix settings";
  config = lib.mkIf config.swarselsystems.modules.stylix {
    stylix = lib.mkIf (!config.swarselsystems.isNixos) (lib.recursiveUpdate
      {
        image = config.swarselsystems.wallpaper;
        targets = config.swarselsystems.stylixHomeTargets;
      }
      config.swarselsystems.stylix);
  };
}
