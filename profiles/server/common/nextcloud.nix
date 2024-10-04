{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.nextcloud {

    sops.secrets.nextcloudadminpass = { owner = "nextcloud"; };

    services.nextcloud = {
      enable = true;
      hostName = "stash.swarsel.win";
      home = "/Vault/apps/nextcloud";
      datadir = "/Vault/data/nextcloud";
      https: true;
      configureRedis = true;
      maxUploadSize = "4G";
      extraApps = {
        inherit (pkgs.nextcloud30Packages.apps) mail calendar contact cospend phonetrack polls tasks;
      };
      config = {
        adminuser = "admin";
        adminpassFile = config.sops.secrets.nextcloudadminpass.path;
      };
    };


    services.nginx = {
      virtualHosts = {
        "stash.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "https://192.168.1.5";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
            # "/push/" = {
            # proxyPass = "http://192.168.2.5:7867";
            # };
            "/.well-known/carddav" = {
              return = "301 $scheme://$host/remote.php/dav";
            };
            "/.well-known/caldav" = {
              return = "301 $scheme://$host/remote.php/dav";
            };
          };
        };
      };
    };
  };

}
