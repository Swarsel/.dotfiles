{ config, lib, nix-secrets, ... }:
let
  secretsDirectory = builtins.toString nix-secrets;
in
{
  services.gammastep = lib.mkIf (!config.swarselsystems.isPublic) {
    enable = true;
    provider = "manual";
    latitude = lib.strings.trim (builtins.readFile "${secretsDirectory}/home/gammastep-latitude");
    longitude = lib.strings.trim (builtins.readFile "${secretsDirectory}/home/gammastep-longitude");
  };
}
