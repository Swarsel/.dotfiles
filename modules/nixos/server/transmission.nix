{ self, pkgs, lib, config, confLib, ... }:
let
  inherit (confLib.gen { name = "transmission"; }) serviceName serviceDomain isHome;

  lidarrUser = "lidarr";
  lidarrGroup = lidarrUser;
  lidarrPort = 8686;
  radarrUser = "radarr";
  radarrGroup = radarrUser;
  radarrPort = 7878;
  sonarrUser = "sonarr";
  sonarrGroup = sonarrUser;
  sonarrPort = 8989;
  readarrUser = "readarr";
  readarrGroup = readarrUser;
  readarrPort = 8787;
  prowlarrUser = "prowlarr";
  prowlarrGroup = prowlarrUser;
  prowlarrPort = 9696;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} and friends on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    # this user/group section is probably unneeded
    users = {
      groups = {
        dockeruser = {
          gid = 1155;
        };
        "${radarrGroup}" = { };
        "${readarrGroup}" = { };
        "${sonarrGroup}" = { };
        "${lidarrGroup}" = { };
        "${prowlarrGroup}" = { };
      };
      users = {
        dockeruser = {
          isSystemUser = true;
          uid = 1155;
          group = "docker";
          extraGroups = [ "users" ];
        };
        "${radarrUser}" = {
          isSystemUser = true;
          group = radarrGroup;
          extraGroups = [ "users" ];
        };
        "${readarrGroup}" = {
          isSystemUser = true;
          group = readarrGroup;
          extraGroups = [ "users" ];
        };
        "${sonarrGroup}" = {
          isSystemUser = true;
          group = sonarrGroup;
          extraGroups = [ "users" ];
        };
        "${lidarrUser}" = {
          isSystemUser = true;
          group = lidarrGroup;
          extraGroups = [ "users" ];
        };
        "${prowlarrGroup}" = {
          isSystemUser = true;
          group = prowlarrGroup;
          extraGroups = [ "users" ];
        };
      };
    };

    virtualisation.docker.enable = true;
    environment.systemPackages = with pkgs; [
      docker
    ];

    topology.self.services = {
      radarr.info = "https://${serviceDomain}/radarr";
      readarr = {
        name = "Readarr";
        info = "https://${serviceDomain}/readarr";
        icon = "${self}/files/topology-images/readarr.png";
      };
      sonarr.info = "https://${serviceDomain}/sonarr";
      lidarr.info = "https://${serviceDomain}/lidarr";
      prowlarr.info = "https://${serviceDomain}/prowlarr";
    };

    globals.services.transmission = {
      domain = serviceDomain;
      inherit isHome;
    };

    services = {
      radarr = {
        enable = true;
        user = radarrUser;
        group = radarrGroup;
        settings.server.port = radarrPort;
        openFirewall = true;
        dataDir = "/Vault/data/radarr";
      };
      readarr = {
        enable = true;
        user = readarrUser;
        group = readarrGroup;
        settings.server.port = readarrPort;
        openFirewall = true;
        dataDir = "/Vault/data/readarr";
      };
      sonarr = {
        enable = true;
        user = sonarrUser;
        group = sonarrGroup;
        settings.server.port = sonarrPort;
        openFirewall = true;
        dataDir = "/Vault/data/sonarr";
      };
      lidarr = {
        enable = true;
        user = lidarrUser;
        group = lidarrGroup;
        settings.server.port = lidarrPort;
        openFirewall = true;
        dataDir = "/Vault/data/lidarr";
      };
      prowlarr = {
        enable = true;
        settings.server.port = prowlarrPort;
        openFirewall = true;
      };

      nginx = {
        virtualHosts = {
          "${serviceDomain}" = {
            enableACME = false;
            forceSSL = false;
            acmeRoot = null;
            locations = {
              "/" = {
                proxyPass = "http://localhost:9091";
                extraConfig = ''
                  client_max_body_size    0;
                '';
              };
              "/radarr" = {
                proxyPass = "http://localhost:${builtins.toString radarrPort}";
                extraConfig = ''
                  client_max_body_size    0;
                '';
              };
              "/readarr" = {
                proxyPass = "http://localhost:${builtins.toString readarrPort}";
                extraConfig = ''
                  client_max_body_size    0;
                '';
              };
              "/sonarr" = {
                proxyPass = "http://localhost:${builtins.toString sonarrPort}";
                extraConfig = ''
                  client_max_body_size    0;
                '';
              };
              "/lidarr" = {
                proxyPass = "http://localhost:${builtins.toString lidarrPort}";
                extraConfig = ''
                  client_max_body_size    0;
                '';
              };
              "/prowlarr" = {
                proxyPass = "http://localhost:${builtins.toString prowlarrPort}";
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
