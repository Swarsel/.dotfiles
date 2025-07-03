{ lib, config, ... }:
{
  options.swarselsystems.modules.blueman = lib.mkEnableOption "blueman config";
  config = lib.mkIf config.swarselsystems.modules.blueman {
    services.blueman.enable = true;
    services.hardware.bolt.enable = true;
  };
}
