{
  flake.modules.nixos.grafana =
    {
      self,
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/grafana";
          name = "grafana";
          port = 3000;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
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

      inherit (config.swarselsystems) sopsFile;

      kanidmDomain = globals.services.kanidm.domain;
      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName}.info = "https://${serviceDomain}";
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
            expectedBodyRegex = "ok|database";
            path = "/api/health";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops.secrets = {
          grafana-admin-pw = {
            inherit sopsFile;
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
          };
          grafana-gotify-token = {
            inherit sopsFile;
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
          };
          grafana-smtp-pw = {
            inherit sopsFile;
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
          };
          kanidm-grafana = {
            group = serviceGroup;
            mode = "0440";
            owner = serviceUser;
            sopsFile = kanidmSopsFile;
          };
        };
        users = {
          users.${serviceUser}.extraGroups = [ "users" ];
          persistentIds.grafana = confLib.mkIds 974;
        };
        services.${serviceName} = {
          enable = true;
          dataDir = serviceDir;
          provision = {
            enable = true;
            alerting = {
              contactPoints.settings = {
                apiVersion = 1;
                contactPoints = [
                  {
                    name = "default";
                    orgId = 1;
                    receivers = [
                      {
                        settings = {
                          httpMethod = "POST";
                          message = "{{ template \"default.message\" . }}";
                          title = "{{ template \"default.title\" . }}";
                          url = "https://${globals.services.gotify.domain}/message?token=$__file{${config.sops.secrets.grafana-gotify-token.path}}";
                        };
                        type = "webhook";
                        uid = "gotify_webhook";
                      }
                      {
                        settings = {
                          addresses = "monitoring@${globals.domains.main}";
                          singleEmail = false;
                        };
                        type = "email";
                        uid = "email_default";
                      }
                    ];
                  }
                ];
              };

              policies.settings = {
                apiVersion = 1;
                policies = [
                  {
                    group_by = [
                      "grafana_folder"
                      "alertname"
                    ];
                    group_interval = "5m";
                    group_wait = "30s";
                    orgId = 1;
                    receiver = "default";
                    repeat_interval = "4h";
                  }
                ];
              };

              rules.settings.apiVersion = 1;
            };
            dashboards.settings.providers = [
              {
                options.path = self + "/files/grafana";
                name = "default";
              }
            ];
          };
          settings = {
            users = {
              allow_sign_up = false;
              default_home_dashboard_path = self + "/files/grafana/service-status.json";
            };
            analytics.reporting_enabled = false;
            "auth.generic_oauth" = {
              allow_assign_grafana_admin = true;
              allow_sign_up = true;
              api_url = "https://${kanidmDomain}/oauth2/openid/grafana/userinfo";
              auth_url = "https://${kanidmDomain}/ui/oauth2";
              client_id = "grafana";
              client_secret = "$__file{${config.sops.secrets.kanidm-grafana.path}}";
              enabled = true;
              icon = "signin";
              login_attribute_path = "preferred_username";
              name = "Kanidm";
              role_attribute_path = "contains(groups[*], 'server_admin') && 'GrafanaAdmin' || contains(groups[*], 'admin') && 'Admin' || contains(groups[*], 'editor') && 'Editor' || 'Viewer'";
              scopes = "openid email profile";
              token_url = "https://${kanidmDomain}/oauth2/token";
              use_pkce = true;
              use_refresh_token = true;
            };
            security = {
              cookie_secure = true;
              disable_gravatar = true;
              disable_initial_admin_creation = true;
              hide_version = true;
              secret_key = "$__file{${config.sops.secrets.grafana-admin-pw.path}}";
            };
            server = {
              domain = serviceDomain;
              enable_gzip = true;
              enforce_domain = true;
              http_addr = "0.0.0.0";
              http_port = servicePort;
              protocol = "http";
              root_url = "https://${serviceDomain}";
            };
            smtp = {
              enabled = true;
              from_address = "monitoring@${globals.domains.main}";
              from_name = "Monitoring";
              host = "${globals.services.mailserver.domain}:587";
              password = "$__file{${config.sops.secrets.grafana-smtp-pw.path}}";
              startTLS_policy = "MandatoryStartTLS";
              user = "notification@${globals.domains.main}";
            };
          };
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = serviceDir;
              group = serviceGroup;
              user = serviceUser;
            }
          ];
        };
        systemd.services.${serviceName}.serviceConfig.RestartSec = lib.mkForce "60";
        nodes = lib.mkMerge [
          {
            ${idmServer} =
              lib.recursiveUpdate
                (confLib.mkKanidmOidcSystem {
                  inherit kanidmSopsFile serviceDomain serviceName;
                  extraGroups = [
                    "grafana.editors"
                    "grafana.admins"
                    "grafana.server-admins"
                  ];
                  originUrl = "https://${serviceDomain}/login/generic_oauth";
                })
                {
                  services.kanidm.provision.systems.oauth2.grafana.claimMaps.groups = {
                    joinType = "array";
                    valuesByGroup = {
                      "grafana.admins" = [ "admin" ];
                      "grafana.editors" = [ "editor" ];
                      "grafana.server-admins" = [ "server_admin" ];
                    };
                  };
                };
          }
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              proxyWebsockets = true;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                proxyWebsockets = true;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];
      };
    }

  ;
}
