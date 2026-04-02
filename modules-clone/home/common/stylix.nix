{ self, lib, config, vars, ... }:
{
  options.swarselmodules.stylix = lib.mkEnableOption "stylix settings";
  config = lib.mkIf config.swarselmodules.stylix {
    stylix = lib.mkIf (!config.swarselsystems.isNixos && config.swarselmodules.stylix) (lib.recursiveUpdate
      {
        enable = true;
        base16Scheme = "${self}/files/stylix/swarsel.yaml";
        targets = vars.stylixHomeTargets;
      }
      vars.stylix);
  };
}
