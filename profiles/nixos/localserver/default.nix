{ lib, config, ... }:
{
  options.swarselsystems.profiles.server.local = lib.mkEnableOption "is this a local server";
  config = lib.mkIf config.swarselsystems.profiles.server.local {
    swarselsystems = {
      modules = {
        general = lib.mkDefault true;
        nix-ld = lib.mkDefault true;
        home-manager = lib.mkDefault true;
        home-managerExtra = lib.mkDefault true;
        xserver = lib.mkDefault true;
        gc = lib.mkDefault true;
        storeOptimize = lib.mkDefault true;
        time = lib.mkDefault true;
        users = lib.mkDefault true;
        server = {
          general = lib.mkDefault true;
          packages = lib.mkDefault true;
          sops = lib.mkDefault true;
          nfs = lib.mkDefault true;
          nginx = lib.mkDefault true;
          ssh = lib.mkDefault true;
          kavita = lib.mkDefault true;
          jellyfin = lib.mkDefault true;
          navidrome = lib.mkDefault true;
          spotifyd = lib.mkDefault true;
          mpd = lib.mkDefault true;
          matrix = lib.mkDefault true;
          nextcloud = lib.mkDefault true;
          immich = lib.mkDefault true;
          paperless = lib.mkDefault true;
          transmission = lib.mkDefault true;
          syncthing = lib.mkDefault true;
          monitoring = lib.mkDefault true;
          emacs = lib.mkDefault true;
          freshrss = lib.mkDefault true;
        };
      };
    };
  };

}
