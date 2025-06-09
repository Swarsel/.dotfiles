{ self, lib, pkgs, config, ... }:
let
  certsSopsFile = self + /secrets/certs/secrets.yaml;
  kanidmDomain = "sso.swarsel.win";
  kanidmPort = 8300;
in
{
  options.swarselsystems.modules.server.kanidm = lib.mkEnableOption "enable kanidm on server";
  config = lib.mkIf config.swarselsystems.modules.server.kanidm {

    users.users.kanidm = {
      group = "kanidm";
      isSystemUser = true;
    };

    users.groups.kanidm = { };

    sops.secrets = {
      "kanidm-self-signed-crt" = { sopsFile = certsSopsFile; owner = "kanidm"; group = "kanidm"; mode = "440"; };
      "kanidm-self-signed-key" = { sopsFile = certsSopsFile; owner = "kanidm"; group = "kanidm"; mode = "440"; };
      "kanidm-admin-pw" = { owner = "kanidm"; group = "kanidm"; mode = "440"; };
      "kanidm-idm-admin-pw" = { owner = "kanidm"; group = "kanidm"; mode = "440"; };
      "kanidm-immich" = { owner = "kanidm"; group = "kanidm"; mode = "440"; };
      "kanidm-paperless" = { owner = "kanidm"; group = "kanidm"; mode = "440"; };
      "kanidm-forgejo" = { owner = "kanidm"; group = "kanidm"; mode = "440"; };
      "kanidm-grafana" = { owner = "kanidm"; group = "kanidm"; mode = "440"; };
    };

    services.kanidm = {
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
          };
        };
      };
    };

    systemd.services.kanidm.serviceConfig.RestartSec = "30";

    services.nginx = {
      virtualHosts = {
        "sso.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "https://localhost:${toString kanidmPort}";
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
