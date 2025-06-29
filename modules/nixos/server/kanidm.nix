{ self, lib, pkgs, config, globals, ... }:
let
  certsSopsFile = self + /secrets/certs/secrets.yaml;
  serviceDomain = "sso.swarsel.win";
  servicePort = 8300;
  serviceUser = "kanidm";
  serviceGroup = serviceUser;
  serviceName = "kanidm";
  oauth2ProxyDomain = globals.services.oauth2Proxy.domain;
in
{
  options.swarselsystems.modules.server."${serviceName}" = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server."${serviceName}" {

    users.users."${serviceUser}" = {
      group = serviceGroup;
      isSystemUser = true;
    };

    users.groups."${serviceGroup}" = { };

    sops = {
      secrets = {
        "kanidm-self-signed-crt" = { sopsFile = certsSopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-self-signed-key" = { sopsFile = certsSopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-admin-pw" = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-idm-admin-pw" = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-immich" = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-paperless" = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-forgejo" = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-grafana" = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-nextcloud" = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-freshrss" = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-oauth2-proxy" = { owner = serviceUser; group = serviceGroup; mode = "0440"; };
      };
    };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    globals.services.${serviceName}.domain = serviceDomain;

    services = {
      kanidm = {
        package = pkgs.kanidmWithSecretProvisioning;
        enableServer = true;
        serverSettings = {
          domain = serviceDomain;
          origin = "https://${serviceDomain}";
          tls_chain = config.sops.secrets.kanidm-self-signed-crt.path;
          tls_key = config.sops.secrets.kanidm-self-signed-key.path;
          bindaddress = "0.0.0.0:${toString servicePort}";
          trust_x_forward_for = true;
        };
        enableClient = true;
        clientSettings = {
          uri = config.services.kanidm.serverSettings.origin;
          verify_ca = true;
          verify_hostnames = true;
        };
        provision = {
          enable = true;
          adminPasswordFile = config.sops.secrets.kanidm-admin-pw.path;
          idmAdminPasswordFile = config.sops.secrets.kanidm-idm-admin-pw.path;
          groups = {
            "immich.access" = { };
            "paperless.access" = { };
            "forgejo.access" = { };
            "forgejo.admins" = { };
            "grafana.access" = { };
            "grafana.editors" = { };
            "grafana.admins" = { };
            "grafana.server-admins" = { };
            "nextcloud.access" = { };
            "nextcloud.admins" = { };
            "navidrome.access" = { };
            "freshrss.access" = { };
            "firefly.access" = { };
            "radicale.access" = { };
          };

          inherit (config.repo.secrets.local) persons;

          systems = {
            oauth2 = {
              immich = {
                displayName = "Immich";
                originUrl = [
                  "https://shots.swarsel.win/auth/login"
                  "https://shots.swarsel.win/user-settings"
                  "app.immich:///oauth-callback"
                  "https://shots.swarsel.win/api/oauth/mobile-redirect"
                ];
                originLanding = "https://shots.swarsel.win/";
                basicSecretFile = config.sops.secrets.kanidm-immich.path;
                preferShortUsername = true;
                enableLegacyCrypto = true; # can use RS256 / HS256, not ES256
                scopeMaps."immich.access" = [
                  "openid"
                  "email"
                  "profile"
                ];
              };
              paperless = {
                displayName = "Paperless";
                originUrl = "https://scan.swarsel.win/accounts/oidc/kanidm/login/callback/";
                originLanding = "https://scan.swarsel.win/";
                basicSecretFile = config.sops.secrets.kanidm-paperless.path;
                preferShortUsername = true;
                scopeMaps."paperless.access" = [
                  "openid"
                  "email"
                  "profile"
                ];
              };
              forgejo = {
                displayName = "Forgejo";
                originUrl = "https://swagit.swarsel.win/user/oauth2/kanidm/callback";
                originLanding = "https://swagit.swarsel.win/";
                basicSecretFile = config.sops.secrets.kanidm-forgejo.path;
                scopeMaps."forgejo.access" = [
                  "openid"
                  "email"
                  "profile"
                ];
                # XXX: PKCE is currently not supported by gitea/forgejo,
                # see https://github.com/go-gitea/gitea/issues/21376.
                allowInsecureClientDisablePkce = true;
                preferShortUsername = true;
                claimMaps.groups = {
                  joinType = "array";
                  valuesByGroup."forgejo.admins" = [ "admin" ];
                };
              };
              grafana = {
                displayName = "Grafana";
                originUrl = "https://status.swarsel.win/login/generic_oauth";
                originLanding = "https://status.swarsel.win/";
                basicSecretFile = config.sops.secrets.kanidm-grafana.path;
                preferShortUsername = true;
                scopeMaps."grafana.access" = [
                  "openid"
                  "email"
                  "profile"
                ];
                claimMaps.groups = {
                  joinType = "array";
                  valuesByGroup = {
                    "grafana.editors" = [ "editor" ];
                    "grafana.admins" = [ "admin" ];
                    "grafana.server-admins" = [ "server_admin" ];
                  };
                };
              };
              nextcloud = {
                displayName = "Nextcloud";
                originUrl = " https://stash.swarsel.win/apps/sociallogin/custom_oidc/kanidm";
                originLanding = "https://stash.swarsel.win/";
                basicSecretFile = config.sops.secrets.kanidm-nextcloud.path;
                allowInsecureClientDisablePkce = true;
                scopeMaps."nextcloud.access" = [
                  "openid"
                  "email"
                  "profile"
                ];
                preferShortUsername = true;
                claimMaps.groups = {
                  joinType = "array";
                  valuesByGroup = {
                    "nextcloud.admins" = [ "admin" ];
                  };
                };
              };
              oauth2-proxy = {
                displayName = "Oauth2-Proxy";
                originUrl = "https://${oauth2ProxyDomain}/oauth2/callback";
                originLanding = "https://${oauth2ProxyDomain}/";
                basicSecretFile = config.sops.secrets.kanidm-oauth2-proxy.path;
                scopeMaps = {
                  "freshrss.access" = [
                    "openid"
                    "email"
                    "profile"
                  ];
                  "navidrome.access" = [
                    "openid"
                    "email"
                    "profile"
                  ];
                  "firefly.access" = [
                    "openid"
                    "email"
                    "profile"
                  ];
                  "radicale.access" = [
                    "openid"
                    "email"
                    "profile"
                  ];
                };
                preferShortUsername = true;
                claimMaps.groups = {
                  joinType = "array";
                  valuesByGroup = {
                    "freshrss.access" = [ "ttrss_access" ];
                    "navidrome.access" = [ "navidrome_access" ];
                    "firefly.access" = [ "firefly_access" ];
                    "radicale.access" = [ "radicale_access" ];
                  };
                };
              };
            };
          };
        };
      };
    };

    systemd.services = {
      kanidm.serviceConfig.RestartSec = "30";
    };

    nodes.moonside.services.nginx = {
      upstreams = {
        "${serviceName}" = {
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
              proxyPass = "https://${serviceName}";
            };
          };
          extraConfig = ''
            proxy_ssl_verify off;
          '';
        };
      };
    };
  };
}
