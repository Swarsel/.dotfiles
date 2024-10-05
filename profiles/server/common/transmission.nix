{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.transmission {

    virtualisation.docker.enable = true;
    environment.systemPackages = with pkgs; [
      docker
    ];

    services = {
      radarr = {
        enable = true;
      };
      readarr = {
        enable = true;
      };
      sonarr = {
        enable = true;
      };
      lidarr = {
        enable = true;
      };
      prowlarr = {
        enable = true;
      };

      nginx = {
        virtualHosts = {
          "store.swarsel.win" = {
            enableACME = false;
            forceSSL = false;
            acmeRoot = null;
            locations = {
              "/" = {
                proxyPass = "http://127.0.0.1:9091";
                extraConfig = ''
                  client_max_body_size    0;
                '';
              };
            };
          };
        };
      };
    };
  };
}
