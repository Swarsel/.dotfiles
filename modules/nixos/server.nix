{ lib, ... }:
{
  options.swarselsystems = {
    server = {
      enable = lib.mkEnableOption "is a server machine";
      kavita = lib.mkEnableOption "enable kavita on server";
      jellyfin = lib.mkEnableOption "enable jellyfin on server";
      navidrome = lib.mkEnableOption "enable navidrome on server";
      spotifyd = lib.mkEnableOption "enable spotifyd on server";
      mpd = lib.mkEnableOption "enable mpd on server";
      matrix = lib.mkEnableOption "enable matrix on server";
      nextcloud = lib.mkEnableOption "enable nextcloud on server";
      immich = lib.mkEnableOption "enable immich on server";
      paperless = lib.mkEnableOption "enable paperless on server";
      transmission = lib.mkEnableOption "enable transmission and friends on server";
      syncthing = lib.mkEnableOption "enable syncthing on server";
      restic = lib.mkEnableOption "enable restic backups on server";
      monitoring = lib.mkEnableOption "enable monitoring on server";
      jenkins = lib.mkEnableOption "enable jenkins on server";
      emacs = lib.mkEnableOption "enable emacs server on server";
      forgejo = lib.mkEnableOption "enable forgejo on server";
      ankisync = lib.mkEnableOption "enable ankisync on server";
      freshrss = lib.mkEnableOption "enable freshrss on server";
    };
  };
}
