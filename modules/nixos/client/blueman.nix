{ lib, config, ... }:
{
  options.swarselmodules.blueman = lib.mkEnableOption "blueman config";
  config = lib.mkIf config.swarselmodules.blueman {
    services.blueman.enable = true;
    services.hardware.bolt.enable = true;
  };
}
