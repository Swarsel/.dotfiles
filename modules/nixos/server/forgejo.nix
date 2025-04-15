{ lib, config, ... }:
{
  options.swarselsystems.modules.server.forgejo = lib.mkEnableOption "enable forgejo on server";
  config = lib.mkIf config.swarselsystems.modules.server.forgejo {

    networking.firewall.allowedTCPPorts = [ 3000 ];

    services.forgejo = {
      enable = true;
      settings = {
        DEFAULT = {
          APP_NAME = "~SwaGit~";
        };
        server = {
          PROTOCOL = "http";
          HTTP_PORT = 3000;
          HTTP_ADDR = "0.0.0.0";
          DOMAIN = "swagit.swarsel.win";
          ROOT_URL = "https://swagit.swarsel.win";
        };
        service = {
          DISABLE_REGISTRATION = true;
          SHOW_REGISTRATION_BUTTON = false;
        };
      };
    };

    services.nginx = {
      virtualHosts = {
        "swagit.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://localhost:3000";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };
      };
    };
  };

}
