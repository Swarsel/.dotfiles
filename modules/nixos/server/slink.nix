{ self, lib, config, ... }:
let
  servicePort = 3000;
  serviceName = "slink";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};
  serviceDir = "/var/lib/slink";

  containerRev = "sha256:98b9442696f0a8cbc92f0447f54fa4bad227af5dcfd6680545fedab2ed28ddd9";
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    virtualisation.oci-containers.containers.${serviceName} = {
      image = "anirdev/slink@${containerRev}";
      environment = {
        "ORIGIN" = "https://${serviceDomain}";
        "TZ" = config.repo.secrets.common.location.timezone;
        "STORAGE_PROVIDER" = "local";
        "IMAGE_MAX_SIZE" = "50M";
        "USER_APPROVAL_REQUIRED" = "true";
      };
      ports = [ "${builtins.toString servicePort}:${builtins.toString servicePort}" ];
      volumes = [
        "${serviceDir}/var/data:/app/var/data"
        "${serviceDir}/images:/app/slink/images"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${serviceDir}/var/data 0750 root root - -"
      "d ${serviceDir}/images   0750 root root - -"
    ];

    networking.firewall.allowedTCPPorts = [ servicePort ];

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = serviceDir; }
    ];

    topology.self.services.${serviceName} = {
      name = lib.swarselsystems.toCapitalized serviceName;
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/shlink.png";
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
          oauth2.enable = true;
          oauth2.allowedGroups = [ "slink_access" ];
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
              setOauth2Headers = false;
            };
            "/image" = {
              proxyPass = "http://${serviceName}";
              setOauth2Headers = false;
              bypassAuth = true;
            };
          };
        };
      };
    };
  };
}
