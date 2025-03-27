{ lib, nix-secrets, ... }:
let
  secretsDirectory = builtins.toString nix-secrets;
in
{
  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = lib.swarselsystems.getSecret "${secretsDirectory}/home/gammastep-latitude";
    longitude = lib.swarselsystems.getSecret "${secretsDirectory}/home/gammastep-longitude";
  };
}
