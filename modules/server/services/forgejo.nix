{
  flake.modules.nixos.forgejo =
    {
      self,
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
        webProxy
        ;

      kanidmDomain = globals.services.kanidm.domain;
      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
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
        sops.secrets.kanidm-forgejo = {
          group = serviceGroup;
          mode = "0440";
          owner = serviceUser;
          sopsFile = kanidmSopsFile;
        };
        # networking.firewall.allowedTCPPorts = [ servicePort ];
        users = {
          users.${serviceUser} = {
            group = serviceGroup;
            isSystemUser = true;
          };
          persistentIds.forgejo = confLib.mkIds 985;
        };
        users.groups.${serviceGroup} = { };
        services.${serviceName} = {
          enable = true;
          group = serviceGroup;
          lfs.enable = lib.mkDefault true;
          settings = {
            DEFAULT.APP_NAME = "~SwaGit~";
            federation = {
              ENABLED = true;
              SHARE_USER_STATISTICS = false;
            };
            oauth2_client = {
              # Never use auto account linking with this, otherwise users cannot change
              # their new user name and they could potentially overtake other users accounts
              # by setting their email address to an existing account.
              # With "login" linking the user must choose a non-existing username first or login
              # with the existing account to link.
              ACCOUNT_LINKING = "login";
              # This does not mean that you cannot register via oauth, but just that there should
              # be a confirmation dialog shown to the user before the account is actually created.
              # This dialog allows changing user name and email address before creating the account.
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
              SECRET="$(< ${config.sops.secrets.kanidm-forgejo.path})"
              if [[ -z "$provider_id" ]]; then
                ${exe} admin auth add-oauth ${args} --secret "$SECRET"
              else
                ${exe} admin auth update-oauth --id "$provider_id" ${args} --secret "$SECRET"
              fi
            '';
          serviceConfig.RestartSec = "60"; # Retry every minute
        };
        nodes = lib.mkMerge [
          {
            ${idmServer} =
              lib.recursiveUpdate
                (confLib.mkKanidmOidcSystem {
                  inherit kanidmSopsFile serviceDomain serviceName;
                  extraGroups = [ "forgejo.admins" ];
                  originUrl = "https://${serviceDomain}/user/oauth2/kanidm/callback";
                })
                {
                  services.kanidm.provision.systems.oauth2.forgejo = {
                    # XXX: PKCE is currently not supported by gitea/forgejo,
                    # see https://github.com/go-gitea/gitea/issues/21376.
                    allowInsecureClientDisablePkce = true;
                    claimMaps.groups = {
                      joinType = "array";
                      valuesByGroup."forgejo.admins" = [ "admin" ];
                    };
                  };
                };
          }
          {
            ${webProxy} = {
              services.nginx =
                confLib.genNginx {
                  inherit
                    serviceAddress
                    serviceDomain
                    serviceName
                    servicePort
                    ;
                  maxBody = 0;
                }
                // {
                  streamConfig = ''
                    server {
                      listen ${toString sshProxyPort};
                      listen [::]:${toString sshProxyPort};
                      proxy_pass ${serviceAddress}:${toString sshListenPort};
                    }
                  '';
                };
              networking.nftables.firewall.rules.forgejo-ssh-to-local = {
                allowedTCPPorts = [ sshProxyPort ];
                from = [ "untrusted" ];
                to = [ "local" ];
              };
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                maxBody = 0;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];

      };
    }

  ;
}
