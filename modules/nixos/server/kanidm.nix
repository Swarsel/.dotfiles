{ self, lib, pkgs, config, ... }:
let
  certsSopsFile = self + /secrets/certs/secrets.yaml;
  kanidmDomain = "sso.swarsel.win";
  oauth2ProxyDomain = "soauth.swarsel.win";
  kanidmPort = 8300;
  oauth2ProxyPort = 3004;
in
{
  options.swarselsystems.modules.server.kanidm = lib.mkEnableOption "enable kanidm on server";
  config = lib.mkIf config.swarselsystems.modules.server.kanidm {

    users.users.kanidm = {
      group = "kanidm";
      isSystemUser = true;
    };

    users.groups.kanidm = { };

    sops = {
      secrets = {
        "oauth2-cookie-secret" = { owner = "oauth2-proxy"; group = "oauth2-proxy"; mode = "0440"; };
        "kanidm-self-signed-crt" = { sopsFile = certsSopsFile; owner = "kanidm"; group = "kanidm"; mode = "0440"; };
        "kanidm-self-signed-key" = { sopsFile = certsSopsFile; owner = "kanidm"; group = "kanidm"; mode = "0440"; };
        "kanidm-admin-pw" = { owner = "kanidm"; group = "kanidm"; mode = "0440"; };
        "kanidm-idm-admin-pw" = { owner = "kanidm"; group = "kanidm"; mode = "0440"; };
        "kanidm-immich" = { owner = "kanidm"; group = "kanidm"; mode = "0440"; };
        "kanidm-paperless" = { owner = "kanidm"; group = "kanidm"; mode = "0440"; };
        "kanidm-forgejo" = { owner = "kanidm"; group = "kanidm"; mode = "0440"; };
        "kanidm-grafana" = { owner = "kanidm"; group = "kanidm"; mode = "0440"; };
        "kanidm-nextcloud" = { owner = "kanidm"; group = "kanidm"; mode = "0440"; };
        "kanidm-freshrss" = { owner = "kanidm"; group = "kanidm"; mode = "0440"; };
        "kanidm-oauth2-proxy" = { owner = "kanidm"; group = "kanidm"; mode = "0440"; };
        "kanidm-oauth2-proxy-client" = { owner = "oauth2-proxy"; group = "oauth2-proxy"; mode = "0440"; };
      };

      templates = {
        "kanidm-oauth2-proxy-client-env" = {
          content = ''
            OAUTH2_PROXY_CLIENT_SECRET="${config.sops.placeholder.kanidm-oauth2-proxy-client}"
            OAUTH2_PROXY_COOKIE_SECRET=${config.sops.placeholder.oauth2-cookie-secret}
          '';
          owner = "oauth2-proxy";
          group = "oauth2-proxy";
          mode = "0440";
        };
      };
    };

    services = {
      kanidm = {
        package = pkgs.kanidmWithSecretProvisioning;
        enableServer = true;
        serverSettings = {
          domain = kanidmDomain;
          origin = "https://${kanidmDomain}";
          tls_chain = config.sops.secrets.kanidm-self-signed-crt.path;
          tls_key = config.sops.secrets.kanidm-self-signed-key.path;
          bindaddress = "0.0.0.0:${toString kanidmPort}";
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
          };
          persons = {
            swarsel = {
              present = true;
              mailAddresses = [ "leon@swarsel.win" ];
              legalName = "Leon Schwarzäugl";
              groups = [
                "immich.access"
                "paperless.access"
                "grafana.access"
                "forgejo.access"
                "nextcloud.access"
                "freshrss.access"
                "navidrome.access"
                "firefly.access"
              ];
              displayName = "Swarsel";
            };
          };
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
              # freshrss = {
              #   displayName = "FreshRSS";
              #   originUrl = "https://signpost.swarsel.win/apps/sociallogin/custom_oidc/kanidm";
              #   originLanding = "https://signpost.swarsel.win/";
              #   basicSecretFile = config.sops.secrets.kanidm-freshrss.path;
              #   allowInsecureClientDisablePkce = true;
              #   scopeMaps."freshrss.access" = [
              #     "openid"
              #     "email"
              #     "profile"
              #   ];
              #   preferShortUsername = true;
              # };
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
                };
                preferShortUsername = true;
                claimMaps.groups = {
                  joinType = "array";
                  valuesByGroup = {
                    "freshrss.access" = [ "ttrss_access" ];
                    "navidrome.access" = [ "navidrome_access" ];
                    "firefly.access" = [ "firefly_access" ];
                  };
                };
              };
            };
          };
        };
      };
      oauth2-proxy = {
        enable = true;
        cookie = {
          domain = ".swarsel.win";
          secure = true;
          expire = "900m";
          secret = null; # set by service EnvironmentFile
        };
        clientSecret = null; # set by service EnvironmentFile
        reverseProxy = true;
        httpAddress = "0.0.0.0:${builtins.toString oauth2ProxyPort}";
        redirectURL = "https://${oauth2ProxyDomain}/oauth2/callback";
        setXauthrequest = true;
        extraConfig = {
          code-challenge-method = "S256";
          whitelist-domain = ".swarsel.win";
          set-authorization-header = true;
          pass-access-token = true;
          skip-jwt-bearer-tokens = true;
          upstream = "static://202";
          oidc-issuer-url = "https://${kanidmDomain}/oauth2/openid/oauth2-proxy";
          provider-display-name = "Kanidm";
        };
        provider = "oidc";
        scope = "openid email";
        loginURL = "https://${kanidmDomain}/ui/oauth2";
        redeemURL = "https://${kanidmDomain}/oauth2/token";
        validateURL = "https://${kanidmDomain}/oauth2/openid/oauth2-proxy/userinfo";
        clientID = "oauth2-proxy";
        email.domains = [ "*" ];
      };
    };

    systemd.services = {
      kanidm.serviceConfig.RestartSec = "30";
      oauth2-proxy = {
        after = [ "kanidm.service" ];
        serviceConfig = {
          RuntimeDirectory = "oauth2-proxy";
          RuntimeDirectoryMode = "0750";
          UMask = "007"; # TODO remove once https://github.com/oauth2-proxy/oauth2-proxy/issues/2141 is fixed
          RestartSec = "60"; # Retry every minute
          EnvironmentFile = [
            config.sops.templates.kanidm-oauth2-proxy-client-env.path
          ];
        };
      };
    };

    services.nginx = {
      upstreams = {
        kanidm = {
          servers = {
            "192.168.1.2:${builtins.toString kanidmPort}" = { };
          };
        };
        oauth2-proxy = {
          servers = {
            "192.168.1.2:${builtins.toString oauth2ProxyPort}" = { };
          };
        };
      };
      virtualHosts = {
        "${kanidmDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "https://kanidm";
            };
          };
          extraConfig = ''
            proxy_ssl_verify off;
          '';
        };
        "${oauth2ProxyDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://oauth2-proxy";
            };
          };
          extraConfig = ''
            proxy_set_header X-Scheme                $scheme;
            proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
          '';
        };
      };
    };
  };
}
