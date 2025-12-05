{ self, lib, config, dns, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "slink"; port = 3000; dir = "/var/lib/slink"; }) servicePort serviceName serviceDomain serviceDir serviceAddress serviceProxy proxyAddress4 proxyAddress6;

  containerRev = "sha256:98b9442696f0a8cbc92f0447f54fa4bad227af5dcfd6680545fedab2ed28ddd9";
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    nodes.stoicclub.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

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

    systemd.tmpfiles.settings."12-slink" = builtins.listToAttrs (
      map
        (path: {
          name = "${serviceDir}/${path}";
          value = {
            d = {
              group = "root";
              user = "root";
              mode = "0750";
            };
          };
        }) [
        "var/data"
        "images"
      ]
    );

    networking.firewall.allowedTCPPorts = [ servicePort ];

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = serviceDir; }
    ];

    topology.self.services.${serviceName} = {
      name = lib.swarselsystems.toCapitalized serviceName;
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/shlink.png";
    };

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
    };

    nodes.${serviceProxy}.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "${serviceAddress}:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          useACMEHost = globals.domains.main;

          forceSSL = true;
          acmeRoot = null;
          oauth2.enable = true;
          oauth2.allowedGroups = [ "slink_access" ];
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
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
