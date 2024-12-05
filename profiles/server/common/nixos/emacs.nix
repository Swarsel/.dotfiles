{ lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.emacs {

    services.emacs = {
      enable = true;
      startWithGraphical = false;
    };

    services.nginx = {
      virtualHosts = {
        "signpost.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://localhost:54169";
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
