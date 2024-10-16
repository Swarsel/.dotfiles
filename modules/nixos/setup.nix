{ lib, ... }:
let
  inherit (lib) mkOption types;
in

{
  options.swarselsystems.flakePath = mkOption {
    type = types.str;
    default = "";
  };
  options.swarselsystems.initialSetup = lib.mkEnableOption "initial setup (no sops keys available)";
  options.swarselsystems.server.enable = lib.mkEnableOption "is a server machine";
  options.swarselsystems.server.kavita = lib.mkEnableOption "enable kavita on server";
  options.swarselsystems.server.jellyfin = lib.mkEnableOption "enable jellyfin on server";
  options.swarselsystems.server.navidrome = lib.mkEnableOption "enable navidrome on server";
  options.swarselsystems.server.spotifyd = lib.mkEnableOption "enable spotifyd on server";
  options.swarselsystems.server.mpd = lib.mkEnableOption "enable mpd on server";
  options.swarselsystems.server.matrix = lib.mkEnableOption "enable matrix on server";
  options.swarselsystems.server.nextcloud = lib.mkEnableOption "enable nextcloud on server";
  options.swarselsystems.server.immich = lib.mkEnableOption "enable immich on server";
  options.swarselsystems.server.paperless = lib.mkEnableOption "enable paperless on server";
  options.swarselsystems.server.transmission = lib.mkEnableOption "enable transmission and friends on server";
  options.swarselsystems.server.syncthing = lib.mkEnableOption "enable syncthing on server";
}
