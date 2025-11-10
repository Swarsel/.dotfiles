{ lib, config, pkgs, globals, ... }:
let
  inherit (config.swarselsystems) sopsFile;

  servicePort = 3004;
  serviceUser = "forgejo";
  serviceGroup = serviceUser;
  serviceName = "forgejo";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};
  serviceAddress = globals.networks.home.hosts.${config.node.name}.ipv4;

  kanidmDomain = globals.services.kanidm.domain;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    networking.firewall.allowedTCPPorts = [ servicePort ];

    users.users.${serviceUser} = {
      group = serviceGroup;
      isSystemUser = true;
    };

    users.groups.${serviceGroup} = { };

    sops.secrets = {
      kanidm-forgejo-client = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
    };

    globals.services.${serviceName}.domain = serviceDomain;

    services.${serviceName} = {
      enable = true;
      stateDir = "/Vault/data/${serviceName}";
      user = serviceUser;
      group = serviceGroup;
      lfs.enable = lib.mkDefault true;
      settings = {
        DEFAULT = {
          APP_NAME = "~SwaGit~";
        };
        server = {
          PROTOCOL = "http";
          HTTP_PORT = servicePort;
          HTTP_ADDR = "0.0.0.0";
          DOMAIN = serviceDomain;
          ROOT_URL = "https://${serviceDomain}";
        };
        # federation.ENABLED = true;
        service = {
          DISABLE_REGISTRATION = false;
          ALLOW_ONLY_INTERNAL_REGISTRATION = false;
          ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
          SHOW_REGISTRATION_BUTTON = false;
        };
        session.COOKIE_SECURE = true;
        oauth2_client = {
          # Never use auto account linking with this, otherwise users cannot change
          # their new user name and they could potentially overtake other users accounts
          # by setting their email address to an existing account.
          # With "login" linking the user must choose a non-existing username first or login
          # with the existing account to link.
          ACCOUNT_LINKING = "login";
          USERNAME = "nickname";
          # This does not mean that you cannot register via oauth, but just that there should
          # be a confirmation dialog shown to the user before the account is actually created.
          # This dialog allows changing user name and email address before creating the account.
          ENABLE_AUTO_REGISTRATION = false;
          REGISTER_EMAIL_CONFIRM = false;
          UPDATE_AVATAR = true;
        };
      };
    };

    systemd.services.${serviceName} = {
      serviceConfig.RestartSec = "60"; # Retry every minute
      preStart =
        let
          exe = lib.getExe config.services.forgejo.package;
          providerName = "kanidm";
          clientId = serviceName;
          args = lib.escapeShellArgs (
            lib.concatLists [
              [
                "--name"
                providerName
              ]
              [
                "--provider"
                "openidConnect"
              ]
              [
                "--key"
                clientId
              ]
              [
                "--auto-discover-url"
                "https://${kanidmDomain}/oauth2/openid/${clientId}/.well-known/openid-configuration"
              ]
              [
                "--scopes"
                "email"
              ]
              [
                "--scopes"
                "profile"
              ]
              [
                "--group-claim-name"
                "groups"
              ]
              [
                "--admin-group"
                "admin"
              ]
              [ "--skip-local-2fa" ]
            ]
          );
        in
        lib.mkAfter ''
          provider_id=$(${exe} admin auth list | ${pkgs.gnugrep}/bin/grep -w '${providerName}' | cut -f1)
          SECRET="$(< ${config.sops.secrets.kanidm-forgejo-client.path})"
          if [[ -z "$provider_id" ]]; then
            ${exe} admin auth add-oauth ${args} --secret "$SECRET"
          else
            ${exe} admin auth update-oauth --id "$provider_id" ${args} --secret "$SECRET"
          fi
        '';
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
              proxyPass = "http://${serviceName}";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };
      };
    };
  };

}
