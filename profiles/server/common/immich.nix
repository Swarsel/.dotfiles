{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.immich {

    users.users.immich = {
      extraGroups = [ "users" ];
    };

    # sops.secrets.nextcloudadminpass = { owner = "nextcloud"; };

    services.immich = {
      enable = true;
      port = 3001;
      openFirewall = true;
      mediaLocation = "/Vault/Eternor/Immich";
    };


    services.nginx = {
      virtualHosts = {
        "shots.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://[::1]:3001";
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
