{ lib, config, ... }:
{
  options.swarselsystems.modules.xserver = lib.mkEnableOption "xserver keymap";
  config = lib.mkIf config.swarselsystems.modules.packages {
    services.xserver = {
      xkb = {
        layout = "us";
        variant = "altgr-intl";
      };
    };
  };
}
