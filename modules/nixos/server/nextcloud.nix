{ pkgs, lib, config, globals, dns, confLib, ... }:
let
  inherit (config.repo.secrets.local.nextcloud) adminuser;
  inherit (config.swarselsystems) sopsFile;
  inherit (confLib.gen { name = "nextcloud"; port = 80; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress serviceProxy proxyAddress4 proxyAddress6;

  nextcloudVersion = "32";
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    nodes.stoicclub.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    sops.secrets = {
      nextcloud-admin-pw = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      kanidm-nextcloud-client = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
    };

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
    };

    services = {
      ${serviceName} = {
        enable = true;
        settings = {
          trusted_proxies = [ "0.0.0.0" ];
          overwriteprotocol = "https";
        };
        package = pkgs."nextcloud${nextcloudVersion}";
        hostName = serviceDomain;
        home = "/Vault/data/${serviceName}";
        datadir = "/Vault/data/${serviceName}";
        https = true;
        configureRedis = true;
        maxUploadSize = "4G";
        extraApps = {
          inherit (pkgs."nextcloud${nextcloudVersion}Packages".apps) mail calendar contacts cospend phonetrack polls tasks sociallogin;
        };
        extraAppsEnable = true;
        config = {
          inherit adminuser;
          adminpassFile = config.sops.secrets.nextcloud-admin-pw.path;
          dbtype = "sqlite";
        };
      };
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
