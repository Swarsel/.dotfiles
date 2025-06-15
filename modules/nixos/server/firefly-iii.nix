{ self, lib, config, ... }:
let
  cfg = config.services.firefly-iii;
  fireflyDomain = "stonks.swarsel.win";
  fireflyUser = "firefly-iii";
  serviceName = "firefly";
in
{
  options.swarselsystems.modules.server.firefly = lib.mkEnableOption "enable firefly-iii on server";
  config = lib.mkIf config.swarselsystems.modules.server.firefly {

    users.users.firefly-iii = {
      group = "nginx";
      isSystemUser = true;
    };

    sops = {
      secrets = {
        "firefly-iii-app-key" = { owner = fireflyUser; group = "nginx"; mode = "0440"; };
      };
    };

    topology.self.services.firefly-iii = {
      name = "Firefly-III";
      info = "https://${fireflyDomain}";
      icon = "${self}/topology/images/firefly-iii.png";
    };

    services = {
      firefly-iii = {
        enable = true;
        user = fireflyUser;
        group = if cfg.enableNginx then "nginx" else fireflyUser;
        dataDir = "/Vault/data/firefly-iii";
        settings = {
          TZ = config.repo.secrets.common.location.timezone;
          APP_URL = "https://${fireflyDomain}";
          APP_KEY_FILE = config.sops.secrets.firefly-iii-app-key.path;
          APP_ENV = "local";
          DB_CONNECTION = "sqlite";
          TRUSTED_PROXIES = "**";
          # AUTHENTICATION_GUARD = "remote_user_guard";
          # AUTHENTICATION_GUARD_HEADER = "X-User";
          # AUTHENTICATION_GUARD_EMAIL = "X-Email";
        };
        enableNginx = true;
        virtualHost = fireflyDomain;
      };

      nginx = {
        virtualHosts = {
          "${fireflyDomain}" = {
            locations = {
              "/api" = {
                extraConfig = ''
                  index index.php;
                  try_files $uri $uri/ /index.php?$query_string;
                  add_header Access-Control-Allow-Methods 'GET, POST, HEAD, OPTIONS';
                  proxy_set_header X-User  "";
                  proxy_set_header X-Email "";
                '';
              };
            };
          };
        };
      };
    };

    nodes.moonside.services.nginx = {
      upstreams = {
        "${serviceName}" = {
          servers = {
            "192.168.1.2:80" = { };
          };
        };
      };
      virtualHosts = {
        "${fireflyDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          # main config is automatically added by nixos firefly config.
          # hence, only provide certificate
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
            "/api" = {
              proxyPass = "http://${serviceName}";
            };
          };
        };
      };
    };
  };
}
