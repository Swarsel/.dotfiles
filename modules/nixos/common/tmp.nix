{ config, lib, ... }:
{
  options.swarselsystems.modules.tmp = lib.mkEnableOption "tmp dir config";
  config = lib.mkIf config.swarselsystems.modules.tmp {
    boot.tmp.useTmpfs = !config.swarselsystems.modules.impermanence true;
  };
}
