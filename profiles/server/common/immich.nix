{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.immich {

    users.users.immich = {
      extraGroups = [ "users" ];
    };

    # sops.secrets.nextcloudadminpass = { owner = "nextcloud"; };

    services.immich = {
      enable = true;
      port = 3001
        openFirewall = true;
      mediaLocation = "/Vault/Eternor/Bilder";
      home = "/Vault/apps/nextcloud";
    };


    services.nginx = {
      virtualHosts = {
        "shots.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://192.168.1.2:3001";
              extraConfig = ''
                client_max_body_size    0;
              '';
            };
          };
        };
      };
    };
  };

}
