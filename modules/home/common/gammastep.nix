{ lib, config, nixosConfig, ... }:
let
  inherit (nixosConfig.repo.secrets.common.location) latitude longitude;
in
{
  options.swarselsystems.modules.gammastep = lib.mkEnableOption "gammastep settings";
  config = lib.mkIf config.swarselsystems.modules.gammastep {
    services.gammastep = lib.mkIf (config.swarselsystems.isNixos && !config.swarselsystems.isPublic) {
      enable = true;
      provider = "manual";
      inherit longitude latitude;
    };
  };
}
