{ self, lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "freshrss"; port = 80; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome webProxy homeWebProxy dnsServer homeServiceAddress nginxAccessRules;

  inherit (config.swarselsystems) sopsFile;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    users = {
      persistentIds = {
        freshrss = confLib.mkIds 986;
      };
      users.${serviceUser} = {
        extraGroups = [ "users" ];
        group = serviceGroup;
        isSystemUser = true;
      };
    };

    users.groups.${serviceGroup} = { };

    sops = {
      secrets = {
        freshrss-pw = { inherit sopsFile; owner = serviceUser; };
        kanidm-freshrss-client = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        # freshrss-oidc-crypto-key = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
      };

      #   templates = {
      #     "freshrss-env" = {
      #       content = ''
      #         DATA_PATH=${config.services.freshrss.dataDir}
      #         OIDC_ENABLED=1
      #         OIDC_PROVIDER_METADATA_URL=https://${kanidmDomain}/.well-known/openid-configuration
      #         OIDC_CLIENT_ID=freshrss
      #         OIDC_CLIENT_SECRET=${config.sops.placeholder.kanidm-freshrss-client}
      #         OIDC_CLIENT_CRYPTO_KEY=${config.sops.placeholder.oidc-crypto-key}
      #         OIDC_REMOTE_USER_CLAIM=preferred_username
      #         OIDC_SCOPES=openid groups email profile
      #         OIDC_X_FORWARDED_HEADERS=X-Forwarded-Host X-Forwarded-Port X-Forwarded-Proto
      #       '';
      #       owner = "freshrss";
      #       group = "freshrss";
      #       mode = "0440";
      #     };
      #   };
    };

    topology.self.services.${serviceName} = {
      name = "FreshRSS";
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6 isHome serviceAddress;
      homeServiceAddress = lib.mkIf isHome homeServiceAddress;
    };

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = "/var/lib/${serviceName}"; user = serviceUser; group = serviceGroup; }];
    };

    services.${serviceName} =
      let
        inherit (config.repo.secrets.local.freshrss) defaultUser;
      in
      {
        inherit defaultUser;
        enable = true;
        virtualHost = serviceDomain;
        baseUrl = "https://${serviceDomain}";
        authType = "form";
        dataDir = "/var/lib/freshrss";
        passwordFile = config.sops.secrets.freshrss-pw.path;
      };

    # systemd.services.freshrss-config.serviceConfig.EnvironmentFile = [
    #   config.sops.templates.freshrss-env.path
    # ];

    nodes =
      let
        genNginx = toAddress: extraConfig: {
          upstreams = {
            ${serviceName} = {
              servers = {
                "${toAddress}:${builtins.toString servicePort}" = { };
              };
            };
          };
          virtualHosts = {
            "${serviceDomain}" = {
              useACMEHost = globals.domains.main;

              forceSSL = true;
              acmeRoot = null;
              oauth2.enable = true;
              oauth2.allowedGroups = [ "ttrss_access" ];
              inherit extraConfig;
              locations = {
                "/" = {
                  proxyPass = "http://${serviceName}";
                };
                "/api" = {
                  proxyPass = "http://${serviceName}";
                  setOauth2Headers = false;
                  bypassAuth = true;
                };
              };
            };
          };
        };
      in
      {
        ${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
          "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
        };
        ${webProxy}.services.nginx = genNginx serviceAddress "";
        ${homeWebProxy}.services.nginx = genNginx homeServiceAddress nginxAccessRules;
      };

  };
}
