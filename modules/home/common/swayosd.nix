{ pkgs, confLib, ... }:
{
  config = {
    swarselsystems.enabledHomeModules = [ "swayosd" ];
    systemd.user.services.swayosd = confLib.overrideTarget "sway-session.target";
    services.swayosd = {
      enable = true;
      package = pkgs.swayosd;
      topMargin = 0.5;
    };
  };
}
