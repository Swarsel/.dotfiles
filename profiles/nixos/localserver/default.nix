{ lib, config, ... }:
{
  options.swarselprofiles.server.local = lib.mkEnableOption "is this a local server";
  config = lib.mkIf config.swarselprofiles.server.local {
    swarselmodules = {
      general = lib.mkDefault true;
      pii = lib.mkDefault true;
      home-manager = lib.mkDefault true;
      xserver = lib.mkDefault true;
      time = lib.mkDefault true;
      users = lib.mkDefault true;
      sops = lib.mkDefault true;
      boot = lib.mkDefault true;
      server = {
        general = lib.mkDefault true;
        packages = lib.mkDefault true;
        nfs = lib.mkDefault true;
        nginx = lib.mkDefault true;
        ssh = lib.mkDefault true;
        kavita = lib.mkDefault true;
        restic = lib.mkDefault true;
        jellyfin = lib.mkDefault true;
        navidrome = lib.mkDefault true;
        spotifyd = lib.mkDefault true;
        mpd = lib.mkDefault true;
        postgresql = lib.mkDefault true;
        matrix = lib.mkDefault true;
        nextcloud = lib.mkDefault true;
        immich = lib.mkDefault true;
        paperless = lib.mkDefault true;
        transmission = lib.mkDefault true;
        syncthing = lib.mkDefault true;
        grafana = lib.mkDefault true;
        emacs = lib.mkDefault true;
        freshrss = lib.mkDefault true;
        jenkins = lib.mkDefault false;
        kanidm = lib.mkDefault true;
        firefly-iii = lib.mkDefault true;
        koillection = lib.mkDefault true;
        radicale = lib.mkDefault true;
        atuin = lib.mkDefault true;
        forgejo = lib.mkDefault true;
        ankisync = lib.mkDefault true;
      };
    };
  };

}
