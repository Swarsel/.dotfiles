{ lib, pkgs, config, ... }:
{
  options.swarselsystems.modules.swayosd = lib.mkEnableOption "swayosd settings";
  config = lib.mkIf config.swarselsystems.modules.swayosd {
    services.swayosd = {
      enable = true;
      package = pkgs.dev.swayosd;
      topMargin = 0.5;
    };
  };
}
