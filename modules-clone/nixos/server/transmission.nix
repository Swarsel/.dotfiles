{ self, pkgs, lib, config, confLib, ... }:
let
  inherit (confLib.gen { name = "transmission"; port = 9091; }) serviceName servicePort serviceDomain;
  inherit (confLib.static) isHome homeServiceAddress homeWebProxy nginxAccessRules;
  inherit (config.swarselsystems) sopsFile;

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

    sops.secrets = {
      pia = { inherit sopsFile; };
    };

    # this user/group section is probably unneeded
    users = {
      persistentIds = {
        prowlarr = confLib.mkIds 971;
        readarr = confLib.mkIds 970;
      };
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

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [
        { directory = "/var/lib/radarr"; user = radarrUser; group = radarrGroup; }
        { directory = "/var/lib/readarr"; user = readarrUser; group = readarrGroup; }
        { directory = "/var/lib/sonarr"; user = sonarrUser; group = sonarrGroup; }
        { directory = "/var/lib/lidarr"; user = lidarrUser; group = lidarrGroup; }
        { directory = "/var/lib/private/prowlarr"; user = prowlarrUser; group = prowlarrGroup; }
      ];
    };

    services = {
      pia = {
        enable = true;
        credentials.credentialsFile = config.sops.secrets.pia.path;
        protocol = "wireguard";
        autoConnect = {
          enable = true;
          region = "sweden";
        };
        portForwarding.enable = true;
        dns.enable = true;
      };
      radarr = {
        enable = true;
        user = radarrUser;
        group = radarrGroup;
        settings.server.port = radarrPort;
        openFirewall = true;
        dataDir = "/var/lib/radarr";
      };
      readarr = {
        enable = true;
        user = readarrUser;
        group = readarrGroup;
        settings.server.port = readarrPort;
        openFirewall = true;
        dataDir = "/var/lib/readarr";
      };
      sonarr = {
        enable = true;
        user = sonarrUser;
        group = sonarrGroup;
        settings.server.port = sonarrPort;
        openFirewall = true;
        dataDir = "/var/lib/sonarr";
      };
      lidarr = {
        enable = true;
        user = lidarrUser;
        group = lidarrGroup;
        settings.server.port = lidarrPort;
        openFirewall = true;
        dataDir = "/var/lib/lidarr";
      };
      prowlarr = {
        enable = true;
        settings.server.port = prowlarrPort;
        openFirewall = true;
      };
    };

    nodes = {
      ${homeWebProxy}.services.nginx = {
        upstreams = {
          transmission = {
            servers = {
              "${homeServiceAddress}:${builtins.toString servicePort}" = { };
            };
          };
          radarr = {
            servers = {
              "${homeServiceAddress}:${builtins.toString radarrPort}" = { };
            };
          };
          readarr = {
            servers = {
              "${homeServiceAddress}:${builtins.toString readarrPort}" = { };
            };
          };
          sonarr = {
            servers = {
              "${homeServiceAddress}:${builtins.toString sonarrPort}" = { };
            };
          };
          lidarr = {
            servers = {
              "${homeServiceAddress}:${builtins.toString lidarrPort}" = { };
            };
          };
          prowlarr = {
            servers = {
              "${homeServiceAddress}:${builtins.toString prowlarrPort}" = { };
            };
          };
        };
        virtualHosts = {
          "${serviceDomain}" = {
            enableACME = false;
            forceSSL = false;
            acmeRoot = null;
            extraConfig = nginxAccessRules;
            locations = {
              "/" = {
                proxyPass = "http://transmission";
                extraConfig = ''
                  client_max_body_size    0;
                '';
              };
              "/radarr" = {
                proxyPass = "http://radarr";
                extraConfig = ''
                  client_max_body_size    0;
                '';
              };
              "/readarr" = {
                proxyPass = "http://readarr";
                extraConfig = ''
                  client_max_body_size    0;
                '';
              };
              "/sonarr" = {
                proxyPass = "http://sonarr";
                extraConfig = ''
                  client_max_body_size    0;
                '';
              };
              "/lidarr" = {
                proxyPass = "http://lidarr";
                extraConfig = ''
                  client_max_body_size    0;
                '';
              };
              "/prowlarr" = {
                proxyPass = "http://prowlarr";
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
