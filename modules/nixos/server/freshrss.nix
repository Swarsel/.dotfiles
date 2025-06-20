{ self, lib, config, ... }:
let
  serviceName = "freshrss";
  serviceDomain = "signpost.swarsel.win";
  serviceUser = "freshrss";
  serviceGroup = serviceName;
in
{
  options.swarselsystems.modules.server.freshrss = lib.mkEnableOption "enable freshrss on server";
  config = lib.mkIf config.swarselsystems.modules.server.freshrss {

    users.users."${serviceUser}" = {
      extraGroups = [ "users" ];
      group = serviceGroup;
      isSystemUser = true;
    };

    users.groups."${serviceGroup}" = { };

    sops = {
      secrets = {
        fresh = { owner = serviceUser; };
        "kanidm-freshrss-client" = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "oidc-crypto-key" = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
      };

      #   templates = {
      #     "freshrss-env" = {
      #       content = ''
      #         DATA_PATH=${config.services.freshrss.dataDir}
      #         OIDC_ENABLED=1
      #         OIDC_PROVIDER_METADATA_URL=https://sso.swarsel.win/.well-known/openid-configuration
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

    topology.self.services.freshrss = {
      name = "FreshRSS";
      info = "https://${serviceDomain}";
      icon = "${self}/topology/images/freshrss.png";
    };

    services.freshrss = {
      enable = true;
      virtualHost = serviceDomain;
      baseUrl = "https://${serviceDomain}";
      authType = "form";
      dataDir = "/Vault/data/tt-rss";
      defaultUser = "Swarsel";
      passwordFile = config.sops.secrets.fresh.path;
    };

    # systemd.services.freshrss-config.serviceConfig.EnvironmentFile = [
    #   config.sops.templates.freshrss-env.path
    # ];

    nodes.moonside.services.nginx = {
      upstreams = {
        "${serviceName}" = {
          servers = {
            "192.168.1.2:80" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          oauth2.enable = true;
          oauth2.allowedGroups = [ "ttrss_access" ];
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
  };
}
