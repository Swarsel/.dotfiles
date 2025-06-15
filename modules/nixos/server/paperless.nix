{ lib, pkgs, config, ... }:
let
  serviceDomain = "scan.swarsel.win";
  servicePort = 28981;
  serviceUser = "paperless";
  serviceGroup = serviceUser;
  serviceName = "paperless";
in
{
  options.swarselsystems.modules.server."${serviceName}" = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server."${serviceName}" {

    users.users."${serviceUser}" = {
      extraGroups = [ "users" ];
    };

    sops.secrets = {
      paperless_admin = { owner = serviceUser; };
      kanidm-paperless-client = {
        owner = serviceUser;
        group = serviceGroup;
        mode = "0440";
      };
    };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    services = {
      paperless = {
        enable = true;
        mediaDir = "/Vault/Eternor/Paperless";
        dataDir = "/Vault/data/paperless";
        user = serviceUser;
        port = servicePort;
        passwordFile = config.sops.secrets.paperless_admin.path;
        address = "0.0.0.0";
        settings = {
          PAPERLESS_OCR_LANGUAGE = "deu+eng";
          PAPERLESS_URL = "https://scan.swarsel.win";
          PAPERLESS_OCR_USER_ARGS = builtins.toJSON {
            optimize = 1;
            invalidate_digital_signatures = true;
            pdfa_image_compression = "lossless";
          };
          PAPERLESS_TIKA_ENABLED = "true";
          PAPERLESS_TIKA_ENDPOINT = "http://localhost:9998";
          PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://localhost:3002";
          PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
          PAPERLESS_SOCIALACCOUNT_PROVIDERS = builtins.toJSON {
            openid_connect = {
              OAUTH_PKCE_ENABLED = "True";
              APPS = [
                rec {
                  provider_id = "kanidm";
                  name = "Kanidm";
                  client_id = "paperless";
                  # secret will be added by paperless-web.service (see below)
                  #secret = "";
                  settings.server_url = "https://sso.swarsel.win/oauth2/openid/${client_id}/.well-known/openid-configuration";
                }
              ];
            };
          };
        };
      };

      tika = {
        enable = true;
        port = 9998;
        openFirewall = false;
        listenAddress = "127.0.0.1";
        enableOcr = true;
      };

      gotenberg = {
        enable = true;
        package = pkgs.stable.gotenberg;
        port = 3002;
        bindIP = "127.0.0.1";
        timeout = "600s";
        chromium.package = pkgs.stable.chromium;
      };
    };


    # Add secret to PAPERLESS_SOCIALACCOUNT_PROVIDERS
    systemd.services.paperless-web.script = lib.mkBefore ''
      oidcSecret=$(< ${config.sops.secrets.kanidm-paperless-client.path})
      export PAPERLESS_SOCIALACCOUNT_PROVIDERS=$(
        ${pkgs.jq}/bin/jq <<< "$PAPERLESS_SOCIALACCOUNT_PROVIDERS" \
          --compact-output \
          --arg oidcSecret "$oidcSecret" '.openid_connect.APPS.[0].secret = $oidcSecret'
                     )
    '';

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
              proxyPass = "http://${serviceName}";
              extraConfig = ''
                client_max_body_size    0;
                proxy_connect_timeout   300;
                proxy_send_timeout      300;
                proxy_read_timeout      300;
                send_timeout            300;
              '';
            };
          };
        };
      };
    };
  };

}
