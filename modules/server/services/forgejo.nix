{
  flake.modules.nixos.forgejo =
    {
      config,
      lib,
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "forgejo";
          port = 3004;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceGroup
        serviceName
        servicePort
        serviceUser
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        idmServer
        isHome
        nginxAccessRules
        notificationMail
        webProxy
        ;

      sshProxyPort = 2222;
      sshListenPort = 2222;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "forgejo" ];
        globals = {
          services = confLib.mkServiceGlobal {
            inherit
              homeServiceAddress
              isHome
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDomain
              serviceName
              ;
            extra = {
              extraConfig.sshUrl = "ssh://${serviceUser}@${serviceDomain}:${toString sshProxyPort}";
              firezoneTcpPorts = [ sshProxyPort ];
            };
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = ''"status":\s*"pass"'';
            failIfBodyMatchesRegex = ''"status":\s*"(fail|warn|inactive|unknown)"'';
            path = "/api/healthz";
          };
          networks = confLib.mkDualFirewallRules {
            tcpPorts = [
              servicePort
              sshListenPort
            ];
          };
        };
        sops.secrets = {
          kanidm-forgejo = {
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
            rekey.keyPrefix = confLib.kanidmSecrets;
          };
          notification-mail-pw.rekey.keyPrefix = notificationMail.keyPrefix;
        };
        users = {
          users.${serviceUser} = {
            group = serviceGroup;
            isSystemUser = true;
          };
          groups.${serviceGroup} = { };
          persistentIds.forgejo = confLib.mkIds 985;
        };
        services.${serviceName} = {
          enable = true;
          group = serviceGroup;
          lfs.enable = lib.mkDefault true;
          secrets.mailer.PASSWD = config.sops.secrets.notification-mail-pw.path;
          settings = {
            DEFAULT.APP_NAME = config.repo.secrets.common.names.forgejo;
            federation = {
              ENABLED = true;
              SHARE_USER_STATISTICS = false;
            };
            mailer = {
              ENABLED = true;
              FROM = "Forgejo <${notificationMail.address}>";
              PROTOCOL = "smtp+starttls";
              SMTP_ADDR = notificationMail.host;
              SMTP_PORT = 587;
              USER = notificationMail.address;
            };
            oauth2_client = {
              # "auto" linking lets users take over accounts by setting a matching email
              ACCOUNT_LINKING = "login";
              # shows a dialog to adjust name and email before the account is created
              ENABLE_AUTO_REGISTRATION = false;
              REGISTER_EMAIL_CONFIRM = false;
              UPDATE_AVATAR = true;
              USERNAME = "nickname";
            };
            server = {
              DOMAIN = serviceDomain;
              HTTP_ADDR = "0.0.0.0";
              HTTP_PORT = servicePort;
              PROTOCOL = "http";
              ROOT_URL = "https://${serviceDomain}";
              SSH_DOMAIN = serviceDomain;
              SSH_LISTEN_HOST = "0.0.0.0";
              SSH_LISTEN_PORT = sshListenPort;
              SSH_PORT = sshProxyPort;
              START_SSH_SERVER = true;
            };
            service = {
              ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
              ALLOW_ONLY_INTERNAL_REGISTRATION = false;
              DISABLE_REGISTRATION = false;
              ENABLE_NOTIFY_MAIL = true;
              SHOW_REGISTRATION_BUTTON = false;
            };
            session.COOKIE_SECURE = true;
          };
          stateDir = "/var/lib/${serviceName}";
          user = serviceUser;
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = "/var/lib/${serviceName}";
              group = serviceGroup;
              user = serviceUser;
            }
          ];
        };
        systemd.services.${serviceName} = {
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
                    "https://${globals.services.kanidm.domain}/oauth2/openid/${clientId}/.well-known/openid-configuration"
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
              SECRET="$(< ${config.sops.secrets.kanidm-forgejo.path})"
              if [[ -z "$provider_id" ]]; then
                ${exe} admin auth add-oauth ${args} --secret "$SECRET"
              else
                ${exe} admin auth update-oauth --id "$provider_id" ${args} --secret "$SECRET"
              fi
            '';
          serviceConfig.RestartSec = "60";
        };
        nodes =
          let
            mkSshProxy =
              {
                address,
                extraConfig ? "",
              }:
              {
                services.nginx.streamConfig = ''
                  server {
                    listen ${toString sshProxyPort};
                    listen [::]:${toString sshProxyPort};
                    proxy_pass ${address}:${toString sshListenPort};
                    ${extraConfig}
                  }
                '';
                networking.nftables.firewall.rules.forgejo-ssh-to-local = {
                  allowedTCPPorts = [ sshProxyPort ];
                  from = [ "untrusted" ];
                  to = [ "local" ];
                };
              };
          in
          lib.mkMerge [
            {
              ${idmServer} =
                lib.recursiveUpdate
                  (confLib.mkKanidmOidcSystem {
                    inherit serviceDomain serviceName;
                    extraGroups = [ "forgejo.admins" ];
                    originUrl = "https://${serviceDomain}/user/oauth2/kanidm/callback";
                  })
                  {
                    services.kanidm.provision.systems.oauth2.forgejo = {
                      # required because of https://github.com/go-gitea/gitea/issues/21376
                      allowInsecureClientDisablePkce = true;
                      claimMaps.groups = {
                        joinType = "array";
                        valuesByGroup."forgejo.admins" = [ "admin" ];
                      };
                    };
                  };
            }
            {
              ${webProxy} = lib.mkMerge [
                {
                  services.nginx = confLib.genNginx {
                    inherit
                      serviceAddress
                      serviceDomain
                      serviceName
                      servicePort
                      ;
                    maxBody = 0;
                  };
                }
                (mkSshProxy { address = serviceAddress; })
              ];
            }
            {
              ${homeWebProxy} = lib.mkIf isHome (
                lib.mkMerge [
                  {
                    services.nginx = confLib.genNginx {
                      inherit serviceDomain serviceName servicePort;
                      extraConfig = nginxAccessRules;
                      maxBody = 0;
                      serviceAddress = homeServiceAddress;
                    };
                  }
                  (mkSshProxy {
                    address = homeServiceAddress;
                    extraConfig = nginxAccessRules;
                  })
                ]
              );
            }
          ];

      };
    };
}
