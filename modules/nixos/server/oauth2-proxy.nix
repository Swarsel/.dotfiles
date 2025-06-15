{ lib, config, ... }:
let
  kanidmDomain = "sso.swarsel.win";
  oauth2ProxyDomain = "soauth.swarsel.win";
  oauth2ProxyPort = 3004;
in
{
  options.swarselsystems.modules.server.oauth2Proxy = lib.mkEnableOption "enable oauth2-proxy on server";
  config = lib.mkIf config.swarselsystems.modules.server.oauth2Proxy {

    sops = {
      secrets = {
        "oauth2-cookie-secret" = { owner = "oauth2-proxy"; group = "oauth2-proxy"; mode = "0440"; };
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

    networking.firewall.allowedTCPPorts = [ oauth2ProxyPort ];

    services = {
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
      oauth2-proxy = {
        # after = [ "kanidm.service" ];
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
        oauth2-proxy = {
          servers = {
            "localhost:${builtins.toString oauth2ProxyPort}" = { };
          };
        };
      };
      virtualHosts = {
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
