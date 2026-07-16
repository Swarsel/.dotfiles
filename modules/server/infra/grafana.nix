{
  flake.modules.nixos.grafana =
    {
      self,
      lib,
      config,
      globals,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "grafana";
          port = 3000;
          dir = "/var/lib/grafana";
        })
        servicePort
        serviceName
        serviceUser
        serviceGroup
        serviceDir
        serviceDomain
        serviceAddress
        proxyAddress4
        proxyAddress6
        ;
      inherit (confLib.static)
        isHome
        webProxy
        homeWebProxy
        idmServer
        homeServiceAddress
        nginxAccessRules
        ;

      inherit (config.swarselsystems) sopsFile;

      kanidmDomain = globals.services.kanidm.domain;
      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];

        sops.secrets = {
          grafana-admin-pw = {
            inherit sopsFile;
            owner = serviceUser;
            group = serviceGroup;
            mode = "0440";
          };
          kanidm-grafana = {
            sopsFile = kanidmSopsFile;
            owner = serviceUser;
            group = serviceGroup;
            mode = "0440";
          };
          grafana-gotify-token = {
            inherit sopsFile;
            owner = serviceUser;
            group = serviceGroup;
            mode = "0440";
          };
          grafana-smtp-pw = {
            inherit sopsFile;
            owner = serviceUser;
            group = serviceGroup;
            mode = "0440";
          };
        };

        users = {
          persistentIds.grafana = confLib.mkIds 974;
          users.${serviceUser}.extraGroups = [ "users" ];
        };

        topology.self.services.${serviceName}.info = "https://${serviceDomain}";

        globals = {
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
          services = confLib.mkServiceGlobal {
            inherit
              serviceName
              serviceDomain
              proxyAddress4
              proxyAddress6
              isHome
              serviceAddress
              homeServiceAddress
              ;
          };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            path = "/api/health";
            expectedBodyRegex = "ok|database";
          };
          dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
        };

        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = serviceDir;
              user = serviceUser;
              group = serviceGroup;
            }
          ];
        };

        services.${serviceName} = {
          enable = true;
          dataDir = serviceDir;
          provision = {
            enable = true;

            dashboards.settings.providers = [
              {
                name = "default";
                options.path = self + "/files/grafana";
              }
            ];

            alerting = {
              contactPoints.settings = {
                apiVersion = 1;
                contactPoints = [
                  {
                    orgId = 1;
                    name = "default";
                    receivers = [
                      {
                        uid = "gotify_webhook";
                        type = "webhook";
                        settings = {
                          url = "https://${globals.services.gotify.domain}/message?token=$__file{${config.sops.secrets.grafana-gotify-token.path}}";
                          httpMethod = "POST";
                          title = "{{ template \"default.title\" . }}";
                          message = "{{ template \"default.message\" . }}";
                        };
                      }
                      {
                        uid = "email_default";
                        type = "email";
                        settings = {
                          addresses = "monitoring@${globals.domains.main}";
                          singleEmail = false;
                        };
                      }
                    ];
                  }
                ];
              };

              policies.settings = {
                apiVersion = 1;
                policies = [
                  {
                    orgId = 1;
                    receiver = "default";
                    group_by = [
                      "grafana_folder"
                      "alertname"
                    ];
                    group_wait = "30s";
                    group_interval = "5m";
                    repeat_interval = "4h";
                  }
                ];
              };

              rules.settings.apiVersion = 1;
            };
          };

          settings = {
            analytics.reporting_enabled = false;
            users = {
              allow_sign_up = false;
              default_home_dashboard_path = self + "/files/grafana/service-status.json";
            };
            security = {
              disable_initial_admin_creation = true;
              secret_key = "$__file{${config.sops.secrets.grafana-admin-pw.path}}";
              cookie_secure = true;
              disable_gravatar = true;
              hide_version = true;
            };
            server = {
              domain = serviceDomain;
              root_url = "https://${serviceDomain}";
              http_port = servicePort;
              http_addr = "0.0.0.0";
              protocol = "http";
              enforce_domain = true;
              enable_gzip = true;
            };
            smtp = {
              enabled = true;
              host = "${globals.services.mailserver.domain}:587";
              user = "notification@${globals.domains.main}";
              password = "$__file{${config.sops.secrets.grafana-smtp-pw.path}}";
              from_address = "monitoring@${globals.domains.main}";
              from_name = "Monitoring";
              startTLS_policy = "MandatoryStartTLS";
            };
            "auth.generic_oauth" = {
              enabled = true;
              name = "Kanidm";
              icon = "signin";
              allow_sign_up = true;
              client_id = "grafana";
              client_secret = "$__file{${config.sops.secrets.kanidm-grafana.path}}";
              scopes = "openid email profile";
              login_attribute_path = "preferred_username";
              auth_url = "https://${kanidmDomain}/ui/oauth2";
              token_url = "https://${kanidmDomain}/oauth2/token";
              api_url = "https://${kanidmDomain}/oauth2/openid/grafana/userinfo";
              use_pkce = true;
              use_refresh_token = true;
              allow_assign_grafana_admin = true;
              role_attribute_path = "contains(groups[*], 'server_admin') && 'GrafanaAdmin' || contains(groups[*], 'admin') && 'Admin' || contains(groups[*], 'editor') && 'Editor' || 'Viewer'";
            };
          };
        };

        systemd.services.${serviceName}.serviceConfig.RestartSec = lib.mkForce "60";

        nodes = lib.mkMerge [
          {
            ${idmServer} =
              lib.recursiveUpdate
                (confLib.mkKanidmOidcSystem {
                  inherit serviceName serviceDomain kanidmSopsFile;
                  originUrl = "https://${serviceDomain}/login/generic_oauth";
                  extraGroups = [
                    "grafana.editors"
                    "grafana.admins"
                    "grafana.server-admins"
                  ];
                })
                {
                  services.kanidm.provision.systems.oauth2.grafana.claimMaps.groups = {
                    joinType = "array";
                    valuesByGroup = {
                      "grafana.editors" = [ "editor" ];
                      "grafana.admins" = [ "admin" ];
                      "grafana.server-admins" = [ "server_admin" ];
                    };
                  };
                };
          }
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                servicePort
                serviceDomain
                serviceName
                ;
              proxyWebsockets = true;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit servicePort serviceDomain serviceName;
                serviceAddress = homeServiceAddress;
                proxyWebsockets = true;
                extraConfig = nginxAccessRules;
              }
            );
          }
        ];
      };
    }

  ;
}
