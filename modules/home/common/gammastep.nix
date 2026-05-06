{ lib, config, confLib, ... }:
let
  inherit (confLib.getConfig.repo.secrets.common.location) latitude longitude;
in
{
  config = {
    swarselsystems.enabledHomeModules = [ "gammastep" ];
    systemd.user.services.gammastep = confLib.overrideTarget "sway-session.target";
    services.gammastep = lib.mkIf (config.swarselsystems.isNixos && !config.swarselsystems.isPublic) {
      enable = true;
      provider = "manual";
      inherit longitude latitude;
    };
  };
}
