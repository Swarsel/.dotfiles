{ lib, config, ... }:
{
  options.swarselsystems.modules.storeOptimize = lib.mkEnableOption "store optimization config";
  config = lib.mkIf config.swarselsystems.modules.storeOptimize {
    nix.optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };
}
