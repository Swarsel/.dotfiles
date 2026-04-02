{ lib, config, ... }:
{
  options.swarselmodules.xserver = lib.mkEnableOption "xserver keymap";
  config = lib.mkIf config.swarselmodules.packages {
    services.xserver = {
      xkb = {
        layout = "us";
        variant = "altgr-intl";
      };
    };
  };
}
