{ lib, pkgs, config, confLib, ... }:
{
  options.swarselmodules.swayosd = lib.mkEnableOption "swayosd settings";
  config = lib.mkIf config.swarselmodules.swayosd {
    systemd.user.services.swayosd = confLib.overrideTarget "sway-session.target";
    services.swayosd = {
      enable = true;
      package = pkgs.dev.swayosd;
      topMargin = 0.5;
    };
  };
}
