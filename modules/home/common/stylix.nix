{ lib, config, vars, ... }:
{
  options.swarselmodules.stylix = lib.mkEnableOption "stylix settings";
  config = lib.mkIf config.swarselmodules.stylix {
    stylix = lib.mkIf (!config.swarselsystems.isNixos) (lib.recursiveUpdate
      {
        image = config.swarselsystems.wallpaper;
        targets = vars.stylixHomeTargets;
      }
      vars.stylix);
  };
}
