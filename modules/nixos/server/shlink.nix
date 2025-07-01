{ self, lib, config, ... }:
let
  servicePort = 8081;
  serviceName = "shlink";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};

  containerRev = "sha256:1a697baca56ab8821783e0ce53eb4fb22e51bb66749ec50581adc0cb6d031d7a";
in
{
  options = {
    swarselsystems.modules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  };
  config = lib.mkIf config.swarselsystems.modules.server.${serviceName} {

    sops = {
      secrets = {
        shlink-api = { };
      };

      templates = {
        "shlink-env" = {
          content = ''
            INITIAL_API_KEY=${config.sops.placeholder.shlink-api}
          '';
        };
      };
    };

    virtualisation.oci-containers.containers.${serviceName} = {
      image = "shlinkio/shlink@${containerRev}";
      environment = {
        "DEFAULT_DOMAIN" = serviceDomain;
        "PORT" = "${builtins.toString servicePort}";
        "USE_HTTPS" = "false";
        "DEFAULT_SHORT_CODES_LENGTH" = "4";
        "WEB_WORKER_NUM" = "1";
        "TASK_WORKER_NUM" = "1";
      };
      environmentFiles = [
        config.sops.templates.shlink-env.path
      ];
      ports = [ "${builtins.toString servicePort}:${builtins.toString servicePort}" ];
      volumes = [ ];
    };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = "/var/lib/containers"; }
    ];

    topology.self.services.${serviceName} = {
      name = lib.swarselsystems.toCapitalized serviceName;
      info = "https://${serviceDomain}";
      icon = "${self}/topology/images/${serviceName}.png";
    };
    globals.services.${serviceName}.domain = serviceDomain;

    services.nginx = {
      upstreams = {
        ${serviceName} = {
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
            };
          };
        };
      };
    };
  };
}
