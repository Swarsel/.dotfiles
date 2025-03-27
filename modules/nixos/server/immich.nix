{ lib, config, ... }:
{
  options.swarselsystems.server.immich = lib.mkEnableOption "enable immich on server";
  config = lib.mkIf config.swarselsystems.server.immich {

    users.users.immich = {
      extraGroups = [ "video" "render" "users" ];
    };

    # sops.secrets.nextcloudadminpass = { owner = "nextcloud"; };

    services.immich = {
      enable = true;
      port = 3001;
      openFirewall = true;
      mediaLocation = "/Vault/Eternor/Immich";
      environment.IMMICH_MACHINE_LEARNING_URL = lib.mkForce "http://localhost:3003";
    };


    services.nginx = {
      virtualHosts = {
        "shots.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://localhost:3001";
              extraConfig = ''
                client_max_body_size    0;

                proxy_http_version 1.1;
                proxy_set_header   Upgrade    $http_upgrade;
                proxy_set_header   Connection "upgrade";
                proxy_redirect     off;

                proxy_read_timeout 600s;
                proxy_send_timeout 600s;
                send_timeout       600s;
              '';
            };
          };
        };
      };
    };

  };

}
