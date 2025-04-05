{ lib, config, nix-secrets, ... }:
let
  secretsDirectory = builtins.toString nix-secrets;
in
{
  options.swarselsystems.modules.gammastep = lib.mkEnableOption "gammastep settings";
  config = lib.mkIf config.swarselsystems.modules.gammastep {
    services.gammastep = {
      enable = true;
      provider = "manual";
      latitude = lib.swarselsystems.getSecret "${secretsDirectory}/home/gammastep-latitude";
      longitude = lib.swarselsystems.getSecret "${secretsDirectory}/home/gammastep-longitude";
    };
  };
}
