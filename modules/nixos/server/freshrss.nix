{ lib, config, ... }:
let
  serviceName = "freshrss";
in
{
  options.swarselsystems.modules.server.freshrss = lib.mkEnableOption "enable freshrss on server";
  config = lib.mkIf config.swarselsystems.modules.server.freshrss {

    users.users.freshrss = {
      extraGroups = [ "users" ];
      group = "freshrss";
      isSystemUser = true;
    };

    users.groups.freshrss = { };

    sops = {
      secrets = {
        fresh = { owner = "freshrss"; };
        "kanidm-freshrss-client" = { owner = "freshrss"; group = "freshrss"; mode = "0440"; };
        "oidc-crypto-key" = { owner = "freshrss"; group = "freshrss"; mode = "0440"; };
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

    services.freshrss = {
      enable = true;
      virtualHost = "signpost.swarsel.win";
      baseUrl = "https://signpost.swarsel.win";
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
        "signpost.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
              extraConfig = ''
                auth_request /oauth2/auth;
                error_page 401 = /oauth2/sign_in;

                # pass information via X-User and X-Email headers to backend,
                # requires running with --set-xauthrequest flag (done by NixOS)
                auth_request_set $user   $upstream_http_x_auth_request_user;
                auth_request_set $email  $upstream_http_x_auth_request_email;
                proxy_set_header X-User  $user;
                proxy_set_header X-Email $email;
                proxy_set_header Remote-User  $user;

                # if you enabled --pass-access-token, this will pass the token to the backend
                auth_request_set $token  $upstream_http_x_auth_request_access_token;
                proxy_set_header X-Access-Token $token;

                # if you enabled --cookie-refresh, this is needed for it to work with auth_request
                auth_request_set $auth_cookie $upstream_http_set_cookie;
                add_header Set-Cookie $auth_cookie;
              '';
            };
            "/oauth2/" = {
              proxyPass = "http://oauth2-proxy";
              extraConfig = ''
                proxy_set_header X-Scheme                $scheme;
                proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
              '';
            };
            "= /oauth2/auth" = {
              proxyPass = "http://oauth2-proxy/oauth2/auth";
              extraConfig = ''
                internal;

                proxy_set_header X-Scheme         $scheme;
                # nginx auth_request includes headers but not body
                proxy_set_header Content-Length   "";
                proxy_pass_request_body           off;
              '';
            };
          };
        };
      };
    };
  };

}
