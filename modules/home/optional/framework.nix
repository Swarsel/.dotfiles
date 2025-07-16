{ lib, config, ... }:
{
  options.swarselmodules.optional.framework = lib.mkEnableOption "optional framework machine settings";
  config = lib.mkIf config.swarselmodules.optional.framework {
    swarselsystems = {
      inputs = {
        "12972:18:Framework_Laptop_16_Keyboard_Module_-_ANSI_Keyboard" = {
          xkb_layout = "us";
          xkb_variant = "altgr-intl";
        };
      };
    };
  };
}
