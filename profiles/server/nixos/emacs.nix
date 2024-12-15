{ lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.emacs {

    networking.firewall.allowedTCPPorts = [ 9812 ];

    services.emacs = {
      enable = true;
      install = true;
      startWithGraphical = false;
    };

    services.nginx = {
      virtualHosts = {
        "signpost.swarsel.win" = {
          enableACME = false;
          forceSSL = false;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://localhost:9812";
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
