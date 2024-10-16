{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.transmission {

    # this user/group section is probably unneeded
    users = {
      groups = {
        dockeruser = {
          gid = 1155;
        };
      };
      users = {
        dockeruser = {
          isSystemUser = true;
          uid = 1155;
          group = "docker";
          extraGroups = [ "users" ];
        };
        radarr = {
          extraGroups = [ "users" ];
        };
        readarr = {
          extraGroups = [ "users" ];
        };
        sonarr = {
          extraGroups = [ "users" ];
        };
        lidarr = {
          extraGroups = [ "users" ];
        };
        prowlarr = {
          extraGroups = [ "users" ];
        };
      };
    };

    virtualisation.docker.enable = true;
    environment.systemPackages = with pkgs; [
      docker
    ];

    services = {
      radarr = {
        enable = true;
        openFirewall = true;
        dataDir = "/Vault/apps/radarr";
      };
      readarr = {
        enable = true;
        openFirewall = true;
        dataDir = "/Vault/apps/readarr";
      };
      sonarr = {
        enable = true;
        openFirewall = true;
        dataDir = "/Vault/apps/sonarr";
      };
      lidarr = {
        enable = true;
        openFirewall = true;
        dataDir = "/Vault/apps/lidarr";
      };
      prowlarr = {
        enable = true;
        openFirewall = true;
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
              "/radarr" = {
                proxyPass = "http://127.0.0.1:8080";
                extraConfig = ''
                  client_max_body_size    0;
                '';
              };
              "/sonarr" = {
                proxyPass = "http://127.0.0.1:8080";
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
