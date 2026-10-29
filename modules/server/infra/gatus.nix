{
  flake.modules.nixos.gatus =
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
          dir = "/var/lib/private/gatus";
          name = "gatus";
          port = 8099;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
        serviceDomain
        serviceName
        servicePort
        ;
      inherit (confLib.static)
        dnsServer
        homeServiceAddress
        idmServer
        isHome
        webProxy
        ;

      alertAddress = config.repo.secrets.common.mail.address3;
      certificateValid = "[CERTIFICATE_EXPIRATION] > 240h";
      mkEndpoint =
        endpoint:
        {
          alerts = [ { type = "email"; } ];
          interval = "1m";
        }
        // endpoint;
      watchdog = {
        group = "home";
        name = "grafana-watchdog";
      };
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          info = "https://${serviceDomain}";
          name = lib.swarselsystems.toCapitalized serviceName;
        };
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
            extra.extraConfig.watchdogUrl = "https://${serviceDomain}/api/v1/endpoints/${watchdog.group}_${watchdog.name}/external?success=true";
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "UP";
            path = "/health";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops = {
          secrets = {
            gatus-smtp-password = { inherit (config.swarselsystems) sopsFile; };
            gatus-watchdog-token.sopsFile = self + /secrets/general/gatus.yaml;
          };
          templates.gatus-env.content = ''
            GATUS_SMTP_PASSWORD=${config.sops.placeholder.gatus-smtp-password}
            GATUS_WATCHDOG_TOKEN=${config.sops.placeholder.gatus-watchdog-token}
          '';
        };
        services.${serviceName} = {
          enable = true;
          environmentFile = config.sops.templates.gatus-env.path;
          settings = {
            alerting.email = {
              default-alert = {
                failure-threshold = 3;
                send-on-resolved = true;
                success-threshold = 2;
              };
              from = alertAddress;
              host = "smtp.gmail.com";
              password = "\${GATUS_SMTP_PASSWORD}";
              port = 587;
              to = "${alertAddress},monitoring@${globals.domains.main}";
              username = alertAddress;
            };
            endpoints = map mkEndpoint [
              {
                conditions = [
                  "[STATUS] == 200"
                  "[BODY].database == ok"
                ];
                group = "home";
                name = "grafana";
                url = "https://${globals.services.grafana.domain}/api/health";
              }
              {
                conditions = [
                  "[STATUS] == 200"
                  "[BODY] == true"
                ];
                group = "home";
                name = "kanidm";
                url = "https://${globals.services.kanidm.domain}/status";
              }
              {
                conditions = [
                  "[STATUS] == 200"
                  certificateValid
                ];
                group = "cloud";
                name = "web-proxy";
                url = "https://${globals.services.oauth2-proxy.domain}/ping";
              }
              {
                conditions = [
                  "[CONNECTED] == true"
                  certificateValid
                ];
                group = "cloud";
                name = "smtp";
                url = "starttls://${globals.services.mailserver.domain}:587";
              }
              {
                conditions = [
                  "[CONNECTED] == true"
                  certificateValid
                ];
                group = "cloud";
                name = "imap";
                url = "tls://${globals.services.mailserver.domain}:993";
              }
              {
                conditions = [ "[DNS_RCODE] == NOERROR" ];
                dns = {
                  query-name = globals.domains.main;
                  query-type = "SOA";
                };
                group = "cloud";
                name = "dns";
                url = globals.hosts.${dnsServer}.wanAddress4;
              }
              {
                conditions = [
                  "[STATUS] == 200"
                  "[BODY] == pat(*Attic Binary Cache*)"
                ];
                group = "cloud";
                name = "binary-cache";
                url = "https://${globals.services.attic.domain}/";
              }
            ];
            external-endpoints = [
              (
                watchdog
                // {
                  alerts = [
                    {
                      failure-threshold = 1;
                      type = "email";
                    }
                  ];
                  heartbeat.interval = "10m";
                  token = "\${GATUS_WATCHDOG_TOKEN}";
                }
              )
            ];
            storage = {
              path = "/var/lib/gatus/data.db";
              type = "sqlite";
            };
            web = {
              address = "0.0.0.0";
              port = servicePort;
            };
          };
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            mode = "0700";
          }
        ];
        nodes = lib.mkMerge [
          {
            ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; };
          }
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              oauth2 = true;
              oauth2Groups = [ "${serviceName}_access" ];
            };
          }
          {
            ${webProxy}.services.nginx.virtualHosts.${serviceDomain}.locations."~ ^/api/v1/endpoints/[^/]+/external$" =
              {
                bypassAuth = true;
                proxyPass = "http://${serviceName}";
                setOauth2Headers = false;
              };
          }
        ];
      };
    }

  ;
}
