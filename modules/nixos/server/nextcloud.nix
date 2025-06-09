{ pkgs, lib, config, ... }:
let
  nextcloudDomain = "stash.swarsel.win";
in
{
  options.swarselsystems.modules.server.nextcloud = lib.mkEnableOption "enable nextcloud on server";
  config = lib.mkIf config.swarselsystems.modules.server.nextcloud {

    sops.secrets = {
      nextcloudadminpass = {
        owner = "nextcloud";
        group = "nextcloud";
        mode = "0440";
      };
      kanidm-nextcloud-client = {
        owner = "nextcloud";
        group = "nextcloud";
        mode = "0440";
      };
    };

    services = {
      nextcloud = {
        enable = true;
        package = pkgs.nextcloud31;
        hostName = nextcloudDomain;
        home = "/Vault/apps/nextcloud";
        datadir = "/Vault/data/nextcloud";
        https = true;
        configureRedis = true;
        maxUploadSize = "4G";
        extraApps = {
          inherit (pkgs.nextcloud30Packages.apps) mail calendar contacts cospend phonetrack polls tasks sociallogin;
        };
        extraAppsEnable = true;
        config = {
          adminuser = "admin";
          adminpassFile = config.sops.secrets.nextcloudadminpass.path;
          dbtype = "sqlite";
        };
      };

      nginx = {
        virtualHosts = {
          "${nextcloudDomain}" = {
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
