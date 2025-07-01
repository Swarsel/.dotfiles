{ pkgs, lib, config, ... }:
let
  inherit (config.repo.secrets.local.nextcloud) adminuser;

  servicePort = 80;
  serviceUser = "nextcloud";
  serviceGroup = serviceUser;
  serviceName = "nextcloud";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};
in
{
  options.swarselsystems.modules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server.${serviceName} {

    sops.secrets = {
      nextcloudadminpass = {
        owner = serviceUser;
        group = serviceGroup;
        mode = "0440";
      };
      kanidm-nextcloud-client = {
        owner = serviceUser;
        group = serviceGroup;
        mode = "0440";
      };
    };


    globals.services.${serviceName}.domain = serviceDomain;

    services = {
      ${serviceName} = {
        enable = true;
        settings = {
          trusted_proxies = [ "0.0.0.0" ];
          overwriteprotocol = "https";
        };
        package = pkgs.nextcloud31;
        hostName = serviceDomain;
        home = "/Vault/data/${serviceName}";
        datadir = "/Vault/data/${serviceName}";
        https = true;
        configureRedis = true;
        maxUploadSize = "4G";
        extraApps = {
          inherit (pkgs.nextcloud30Packages.apps) mail calendar contacts cospend phonetrack polls tasks sociallogin;
        };
        extraAppsEnable = true;
        config = {
          inherit adminuser;
          adminpassFile = config.sops.secrets.nextcloudadminpass.path;
          dbtype = "sqlite";
        };
      };
    };

    nodes.moonside.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "192.168.1.2:${builtins.toString servicePort}" = { };
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
