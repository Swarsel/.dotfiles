{ lib, pkgs, config, ... }:
{
  options.swarselmodules.swayosd = lib.mkEnableOption "swayosd settings";
  config = lib.mkIf config.swarselmodules.swayosd {
    services.swayosd = {
      enable = true;
      package = pkgs.dev.swayosd;
      topMargin = 0.5;
    };
  };
}
