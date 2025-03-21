{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.nextcloud {

    sops.secrets.nextcloudadminpass = {
      owner = "nextcloud";
      group = "nextcloud";
      mode = "0440";
    };

    services = {
      nextcloud = {
        enable = true;
        package = pkgs.nextcloud31;
        hostName = "stash.swarsel.win";
        home = "/Vault/apps/nextcloud";
        datadir = "/Vault/data/nextcloud";
        https = true;
        configureRedis = true;
        maxUploadSize = "4G";
        extraApps = {
          inherit (pkgs.nextcloud30Packages.apps) mail calendar contacts cospend phonetrack polls tasks;
        };
        config = {
          adminuser = "admin";
          adminpassFile = config.sops.secrets.nextcloudadminpass.path;
          dbtype = "sqlite";
        };
      };

      nginx = {
        virtualHosts = {
          "stash.swarsel.win" = {
            enableACME = true;
            forceSSL = true;
            acmeRoot = null;
            # config is automatically added by nixos nextcloud config.
            # hence, only provide certificate
          };
        };
      };
    };
  };

}
