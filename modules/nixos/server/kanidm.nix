{ self, lib, pkgs, config, globals, ... }:
let
  certsSopsFile = self + /secrets/certs/secrets.yaml;
  inherit (config.swarselsystems) sopsFile;

  servicePort = 8300;
  serviceUser = "kanidm";
  serviceGroup = serviceUser;
  serviceName = "kanidm";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};
  serviceAddress = globals.networks.home.hosts.${config.node.name}.ipv4;

  oauth2ProxyDomain = globals.services.oauth2Proxy.domain;
  immichDomain = globals.services.immich.domain;
  paperlessDomain = globals.services.paperless.domain;
  forgejoDomain = globals.services.forgejo.domain;
  grafanaDomain = globals.services.grafana.domain;
  nextcloudDomain = globals.services.nextcloud.domain;

  certBase = "/etc/ssl";
  certsDir = "${certBase}/certs";
  privateDir = "${certBase}/private";
  certPathBase = "${certsDir}/${serviceName}.crt";
  certPath =
    if config.swarselsystems.isImpermanence then
      "/persist${certPathBase}"
    else
      "${certPathBase}";
  keyPathBase = "${privateDir}/${serviceName}.key";
  keyPath =
    if config.swarselsystems.isImpermanence then
      "/persist${keyPathBase}"
    else
      "${keyPathBase}";
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    users.users.${serviceUser} = {
      group = serviceGroup;
      isSystemUser = true;
    };

    users.groups.${serviceGroup} = { };

    sops = {
      secrets = {
        "kanidm-self-signed-crt" = { sopsFile = certsSopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-self-signed-key" = { sopsFile = certsSopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-admin-pw" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-idm-admin-pw" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-immich" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-paperless" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-forgejo" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-grafana" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-nextcloud" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-freshrss" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        "kanidm-oauth2-proxy" = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      };
    };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    globals.services.${serviceName}.domain = serviceDomain;

    environment.persistence."/persist" = lib.mkIf config.swarselsystems.isImpermanence {
      files = [
        certPathBase
        keyPathBase
      ];
    };

    system.activationScripts."createPersistentStorageDirs" = lib.mkIf config.swarselsystems.isImpermanence {
      deps = [ "generateSSLCert-${serviceName}" "users" "groups" ];
    };
    system.activationScripts."generateSSLCert-${serviceName}" =
      let
        daysValid = 3650;
        renewBeforeDays = 365;
      in
      {
        text = ''
          set -eu

          ${pkgs.coreutils}/bin/install -d -m 0755 ${certsDir}
          ${if config.swarselsystems.isImpermanence then "${pkgs.coreutils}/bin/install -d -m 0755 /persist${certsDir}" else ""}
          ${pkgs.coreutils}/bin/install -d -m 0750 ${privateDir}
          ${if config.swarselsystems.isImpermanence then "${pkgs.coreutils}/bin/install -d -m 0750 /persist${privateDir}" else ""}

          need_gen=0
          if [ ! -f "${certPathBase}" ] || [ ! -f "${keyPathBase}" ]; then
            need_gen=1
          else
            enddate="$(${pkgs.openssl}/bin/openssl x509 -noout -enddate -in "${certPathBase}" | cut -d= -f2)"
            end_epoch="$(${pkgs.coreutils}/bin/date -d "$enddate" +%s)"
            now_epoch="$(${pkgs.coreutils}/bin/date +%s)"
            seconds_left=$(( end_epoch - now_epoch ))
            days_left=$(( seconds_left / 86400 ))
            if [ "$days_left" -lt ${toString renewBeforeDays} ]; then
              need_gen=1
            fi
          fi

          if [ "$need_gen" -eq 1 ]; then
            ${pkgs.openssl}/bin/openssl req -x509 -nodes -days ${toString daysValid} -newkey rsa:4096 -sha256 \
              -keyout "${keyPath}" \
              -out "${certPath}" \
              -subj "/CN=${serviceDomain}" \
              -addext "subjectAltName=DNS:${serviceDomain}"

            chmod 0644 "${certPath}"
            chmod 0600 "${keyPath}"
            chown ${serviceUser}:${serviceGroup} "${certPath}" "${keyPath}"
          fi
        '';
        deps = [
          "etc"
          (lib.mkIf config.swarselsystems.isImpermanence "specialfs")
        ];
      };

    services = {
      ${serviceName} = {
        package = pkgs.kanidmWithSecretProvisioning_1_7;
        enableServer = true;
        serverSettings = {
          domain = serviceDomain;
          origin = "https://${serviceDomain}";
          # tls_chain = config.sops.secrets.kanidm-self-signed-crt.path;
          tls_chain = certPathBase;
          # tls_key = config.sops.secrets.kanidm-self-signed-key.path;
          tls_key = keyPathBase;
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
            "slink.access" = { };
            "opkssh.access" = { };
          };

          inherit (config.repo.secrets.local) persons;

          systems = {
            oauth2 = {
              immich = {
                displayName = "Immich";
                originUrl = [
                  "https://${immichDomain}/auth/login"
                  "https://${immichDomain}/user-settings"
                  "app.immich:///oauth-callback"
                  "https://${immichDomain}/api/oauth/mobile-redirect"
                ];
                originLanding = "https://${immichDomain}/";
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
                originUrl = "https://${paperlessDomain}/accounts/oidc/kanidm/login/callback/";
                originLanding = "https://${paperlessDomain}/";
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
                originUrl = "https://${forgejoDomain}/user/oauth2/kanidm/callback";
                originLanding = "https://${forgejoDomain}/";
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
                originUrl = "https://${grafanaDomain}/login/generic_oauth";
                originLanding = "https://${grafanaDomain}/";
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
                originUrl = " https://${nextcloudDomain}/apps/sociallogin/custom_oidc/kanidm";
                originLanding = "https://${nextcloudDomain}/";
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
              opkssh = {
                displayName = "OPKSSH";
                originUrl = [
                  "http://localhost:3000"
                  "http://localhost:3000/login-callback"
                  "http://localhost:10001/login-callback"
                  "http://localhost:11110/login-callback"
                ];
                originLanding = "http://localhost:3000";
                public = true;
                enableLocalhostRedirects = true;
                scopeMaps."opkssh.access" = [
                  "openid"
                  "email"
                  "profile"
                ];
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
                  "slink.access" = [
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
                    "slink.access" = [ "slink_access" ];
                  };
                };
              };
            };
          };
        };
      };
    };

    systemd.services = {
      ${serviceName}.serviceConfig.RestartSec = "30";
    };

    nodes.moonside.services.nginx = {
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
