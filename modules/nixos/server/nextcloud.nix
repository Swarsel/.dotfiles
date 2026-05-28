{ self, pkgs, lib, config, confLib, ... }:
let
  inherit (config.repo.secrets.local.nextcloud) adminuser;
  inherit (config.swarselsystems) sopsFile;
  inherit (confLib.gen { name = "nextcloud"; port = 80; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome idmServer webProxy homeWebProxy homeServiceAddress nginxAccessRules;

  nextcloudVersion = "33";

  kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
in
{
  imports = [
    "${self}/modules/nixos/server/nginx.nix"
  ];

  config = {
    swarselsystems.enabledServerModules = [ "nextcloud" ];

    sops.secrets = {
      nextcloud-admin-pw = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      kanidm-nextcloud = { sopsFile = kanidmSopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
    };

    users.persistentIds = {
      nextcloud = confLib.mkIds 990;
      redis-nextcloud = confLib.mkIds 976;
    };

    globals = {
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
      monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; path = "/status.php"; expectedBodyRegex = ''"installed":\s*true''; hostHeader = serviceDomain; };
      dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
    };

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [
        { directory = "/var/lib/${serviceName}"; user = serviceUser; group = serviceGroup; }
        { directory = "/var/lib/redis-${serviceName}"; user = serviceUser; group = serviceGroup; }
      ];
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
        home = "/var/lib/${serviceName}";
        datadir = "/var/lib/${serviceName}";
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



    nodes = {
      ${idmServer} = lib.recursiveUpdate
        (confLib.mkKanidmOidcSystem {
          inherit serviceName serviceDomain kanidmSopsFile;
          originUrl = " https://${serviceDomain}/apps/sociallogin/custom_oidc/kanidm";
          extraGroups = [ "nextcloud.admins" ];
        })
        {
          services.kanidm.provision.systems.oauth2.nextcloud = {
            allowInsecureClientDisablePkce = true;
            claimMaps.groups = {
              joinType = "array";
              valuesByGroup."nextcloud.admins" = [ "admin" ];
            };
          };
        };
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; maxBody = 0; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };
}
