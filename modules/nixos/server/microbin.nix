{ lib, config, ... }:
let
  serviceDomain = "scratch.swarsel.win";
  servicePort = 8777;
  serviceName = "microbin";
  serviceUser = "microbin";
  serviceGroup = serviceUser;

  cfg = config.services."${serviceName}";
in
{
  options.swarselsystems.modules.server."${serviceName}" = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server."${serviceName}" {

    users = {
      groups."${serviceGroup}" = { };

      users."${serviceUser}" = {
        isSystemUser = true;
        group = serviceGroup;
      };
    };

    sops = {
      secrets = {
        microbin-admin-username = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
        microbin-admin-password = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
        microbin-uploader-password = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
      };

      templates = {
        "microbin-env" = {
          content = ''
            MICROBIN_ADMIN_USERNAME="${config.sops.placeholder.microbin-admin-username}"
            MICROBIN_ADMIN_PASSWORD="${config.sops.placeholder.microbin-admin-password}"
            MICROBIN_UPLOADER_PASSWORD="${config.sops.placeholder.microbin-uploader-password}"
          '';
          owner = serviceUser;
          group = serviceGroup;
          mode = "0440";
        };
      };
    };

    topology.self.services."${serviceName}".info = "https://${serviceDomain}";

    services."${serviceName}" = {
      enable = true;
      passwordFile = config.sops.templates.microbin-env.path;
      dataDir = "/var/lib/microbin";
      settings = {
        MICROBIN_HIDE_LOGO = true;
        MICROBIN_PORT = servicePort;
        MICROBIN_EDITABLE = true;
        MICROBIN_HIDE_HEADER = true;
        MICROBIN_HIDE_FOOTER = true;
        MICROBIN_NO_LISTING = false;
        MICROBIN_HIGHLIGHTSYNTAX = true;
        MICROBIN_BIND = "0.0.0.0";
        MICROBIN_PRIVATE = true;
        MICROBIN_PUBLIC_PATH = "https://${serviceDomain}";
        MICROBIN_READONLY = true;
        MICROBIN_SHOW_READ_STATS = true;
        MICROBIN_TITLE = "~SwarselScratch~";
        MICROBIN_THREADS = 1;
        MICROBIN_GC_DAYS = 30;
        MICROBIN_ENABLE_BURN_AFTER = true;
        MICROBIN_QR = true;
        MICROBIN_ETERNAL_PASTA = true;
        MICROBIN_ENABLE_READONLY = true;
        MICROBIN_DEFAULT_EXPIRY = "1week";
        MICROBIN_NO_FILE_UPLOAD = false;
        MICROBIN_MAX_FILE_SIZE_ENCRYPTED_MB = 256;
        MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = 1024;
        MICROBIN_DISABLE_UPDATE_CHECKING = true;
        MICROBIN_DISABLE_TELEMETRY = true;
        MICROBIN_LIST_SERVER = false;
      };
    };

    systemd.services = {
      "${serviceName}" = {
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = serviceUser;
          Group = serviceGroup;
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = cfg.dataDir; user = serviceUser; group = serviceGroup; mode = "0700"; }
    ];

    services.nginx = {
      upstreams = {
        "${serviceName}" = {
          servers = {
            "localhost:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
              extraConfig = ''
                client_max_body_size 1G;
              '';
            };
          };
        };
      };
    };

  };

}
