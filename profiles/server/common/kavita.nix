{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.kavita {
    environment.systemPackages = with pkgs; [
      calibre
    ];

    sops.secrets.kavita = { owner = "kavita"; };

    networking.firewall.allowedTCPPorts = [ 8080 ];

    services.kavita = {
      enable = true;
      user = "kavita";
      settings.Port = 8080;
      tokenKeyFile = config.sops.secrets.kavita.path;
    };

    services.nginx = {
      virtualHosts = {
        "scroll.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://192.168.1.2:8080";
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
