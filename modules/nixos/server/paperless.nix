{ lib, pkgs, config, dns, globals, confLib, ... }:
let
  inherit (config.swarselsystems) sopsFile;
  inherit (confLib.gen { name = "paperless"; port = 28981; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress serviceProxy proxyAddress4 proxyAddress6;

  tikaPort = 9998;
  gotenbergPort = 3002;
  kanidmDomain = globals.services.kanidm.domain;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    users.users.${serviceUser} = {
      extraGroups = [ "users" ];
    };

    sops.secrets = {
      paperless-admin-pw = { inherit sopsFile; owner = serviceUser; };
      kanidm-paperless-client = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
    };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
    };

    services = {
      ${serviceName} = {
        enable = true;
        mediaDir = "/Vault/Eternor/Paperless";
        dataDir = "/Vault/data/${serviceName}";
        user = serviceUser;
        port = servicePort;
        passwordFile = config.sops.secrets.paperless-admin-pw.path;
        address = "0.0.0.0";
        settings = {
          PAPERLESS_OCR_LANGUAGE = "deu+eng";
          PAPERLESS_URL = "https://${serviceDomain}";
          PAPERLESS_OCR_USER_ARGS = builtins.toJSON {
            optimize = 1;
            invalidate_digital_signatures = true;
            pdfa_image_compression = "lossless";
          };
          PAPERLESS_TIKA_ENABLED = "true";
          PAPERLESS_TIKA_ENDPOINT = "http://localhost:${builtins.toString tikaPort}";
          PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://localhost:${builtins.toString gotenbergPort}";
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
                  settings.server_url = "https://${kanidmDomain}/oauth2/openid/${client_id}/.well-known/openid-configuration";
                }
              ];
            };
          };
        };
      };

      tika = {
        enable = true;
        port = tikaPort;
        openFirewall = false;
        listenAddress = "127.0.0.1";
        enableOcr = true;
      };

      gotenberg = {
        enable = true;
        package = pkgs.stable.gotenberg;
        port = gotenbergPort;
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

    nodes.${serviceProxy}.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "${serviceAddress}:${builtins.toString servicePort}" = { };
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
