{ pkgs, lib, config, globals, ... }:
let
  inherit (config.repo.secrets.local.nextcloud) adminuser;
  inherit (config.swarselsystems) sopsFile;

  servicePort = 80;
  serviceUser = "nextcloud";
  serviceGroup = serviceUser;
  serviceName = "nextcloud";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};
  serviceAddress = globals.hosts.winters.ipv4;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    sops.secrets = {
      nextcloud-admin-pw = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      kanidm-nextcloud-client = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
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
          inherit (pkgs.nextcloud31Packages.apps) mail calendar contacts cospend phonetrack polls tasks sociallogin;
        };
        extraAppsEnable = true;
        config = {
          inherit adminuser;
          adminpassFile = config.sops.secrets.nextcloud-admin-pw.path;
          dbtype = "sqlite";
        };
      };
    };

    nodes.moonside.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "${serviceAddress}:${builtins.toString servicePort}" = { };
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
                client_max_body_size    0;
              '';
            };
          };
        };
      };
    };
  };
}
