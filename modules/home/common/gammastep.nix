{ lib, config, confLib, ... }:
let
  inherit (confLib.getConfig.repo.secrets.common.location) latitude longitude;
in
{
  options.swarselmodules.gammastep = lib.mkEnableOption "gammastep settings";
  config = lib.mkIf config.swarselmodules.gammastep {
    services.gammastep = lib.mkIf (config.swarselsystems.isNixos && !config.swarselsystems.isPublic) {
      enable = true;
      provider = "manual";
      inherit longitude latitude;
    };
  };
}
