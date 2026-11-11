{
  flake.modules.nixos.crowdsec =
    {
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      bootstrap = config.swarselsystems.crowdsecBootstrap;
      withNginx = config.services.nginx.enable;
      jumphost = globals.hosts.${globals.general.jumphost};
      homeWan = globals.networks.home-wan;
      allowlist = config.repo.secrets.local.crowdsec;
      allowlistIps = allowlist.allowlistIps or [ ];
      allowlistCidrs = allowlist.allowlistCidrs or [ ];
      allowlistCountryScenarios = allowlist.allowlistCountryScenarios or { };
      stateDir = "/var/lib/crowdsec/state";
      lapiPort = 8089;
    in
    {
      options.swarselsystems.crowdsecBootstrap = lib.mkEnableOption "create lapi, capi, and bouncer api key. afterwards they can be added to sops and this disabled";
      config = {
        swarselsystems.enabledServerModules = [ "crowdsec" ];
        globals.monitoring.http = confLib.mkHttpMonitoring {
          expectedStatus = 403;
          path = "/v1/decisions";
          serviceName = "crowdsec-${config.node.name}";
          servicePort = lapiPort;
        };
        sops.secrets = lib.mkIf (!bootstrap) (
          lib.genAttrs [ "crowdsec-bouncer-key" "crowdsec-capi" "crowdsec-lapi" ] (_: {
            group = "crowdsec";
            mode = "0400";
            owner = "crowdsec";
          })
        );
        users = {
          users.crowdsec.extraGroups = lib.optional withNginx "nginx";
          persistentIds.crowdsec = confLib.mkIds 946;
        };
        services = {
          crowdsec = {
            enable = true;
            autoUpdateService = true;
            hub.collections = [
              "crowdsecurity/linux"
              "crowdsecurity/sshd"
            ]
            ++ lib.optionals withNginx [
              "crowdsecurity/nginx"
              "crowdsecurity/base-http-scenarios"
              "crowdsecurity/http-cve"
            ];
            settings = {
              config = {
                api = {
                  client.credentials_path =
                    if bootstrap then "${stateDir}/lapi.yaml" else config.sops.secrets.crowdsec-lapi.path;
                  server = {
                    listen_uri = "127.0.0.1:${toString lapiPort}";
                    online_client.credentials_path =
                      if bootstrap then "${stateDir}/capi.yaml" else config.sops.secrets.crowdsec-capi.path;
                  };
                };
                config_paths.data_dir = stateDir;
                prometheus.listen_port = 6060;
              };
              acquisitions = [
                {
                  journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
                  labels.type = "syslog";
                  source = "journalctl";
                }
              ]
              ++ lib.optional withNginx {
                filenames = [
                  "/var/log/nginx/access.log"
                  "/var/log/nginx/error.log"
                ];
                labels.type = "nginx";
                source = "file";
              };
              parsers.s02Enrich = [
                {
                  name = "local/private-networks";
                  whitelist = {
                    cidr = [
                      "10.0.0.0/8"
                      "172.16.0.0/12"
                      "192.168.0.0/16"
                      "fc00::/7"
                    ];
                    reason = "private networks";
                  };
                }
                {
                  name = "local/home-wan";
                  whitelist = {
                    cidr = [
                      homeWan.cidrv4
                      homeWan.cidrv6
                    ];
                    reason = "home wan";
                  };
                }
              ]
              ++ lib.optional withNginx {
                name = "local/attic-cache";
                whitelist = {
                  expression = [ "evt.Meta.http_path matches `\\.nar(info)?$`" ];
                  reason = "attic cache lookups";
                };
              }
              ++ lib.optional (allowlistIps != [ ] || allowlistCidrs != [ ]) {
                name = "local/allowlist";
                whitelist = {
                  cidr = allowlistCidrs;
                  ip = allowlistIps;
                  reason = "allowlisted addresses";
                };
              };
              postOverflows.s01Whitelist = [
                {
                  name = "local/hosts";
                  whitelist = {
                    ip = lib.filter (a: a != null) (
                      lib.concatMap (h: [
                        h.wanAddress4
                        h.wanAddress6
                      ]) (lib.attrValues globals.hosts)
                    );
                    reason = "host wan addresses";
                  };
                }
                {
                  name = "local/allowlist-as";
                  whitelist = {
                    expression = map (
                      asn: "evt.Overflow.Alert.Source.AsNumber == '${toString asn}'"
                    ) allowlist.allowlistAs;
                    reason = "allowlisted as";
                  };
                }
              ]
              ++ lib.optional (allowlistCountryScenarios != { }) {
                name = "local/allowlist-country-scenarios";
                whitelist = {
                  expression = lib.flatten (
                    lib.mapAttrsToList (
                      country:
                      map (
                        scenario:
                        "evt.Overflow.Alert.Source.Cn == '${country}' && evt.Overflow.Alert.GetScenario() contains '${scenario}'"
                      )
                    ) allowlistCountryScenarios
                  );
                  reason = "noisy scenarios from home country";
                };
              };
            };
          };
          crowdsec-firewall-bouncer = {
            enable = true;
            createRulesets = false;
            registerBouncer.enable = bootstrap;
            secrets.apiKeyPath = lib.mkIf (!bootstrap) config.sops.secrets.crowdsec-bouncer-key.path;
          };
        };
        environment = {
          etc."alloy/config.alloy".text = lib.mkIf config.services.alloy.enable (
            lib.mkAfter ''
              prometheus.scrape "crowdsec" {
                targets         = [{"__address__" = "127.0.0.1:${toString config.services.crowdsec.settings.config.prometheus.listen_port}"}]
                forward_to      = [prometheus.remote_write.mimir.receiver]
                job_name        = "crowdsec"
                scrape_interval = "30s"
              }
            ''
          );
          persistence."/persist" = lib.mkIf config.swarselsystems.isImpermanence {
            directories = [
              {
                directory = "/var/lib/crowdsec";
                group = "crowdsec";
                mode = "0750";
                user = "crowdsec";
              }
            ];
          };
        };
        networking.nftables.ruleset = ''
          table ip crowdsec {
            set crowdsec-blacklists {
              type ipv4_addr
              flags timeout
            }
            chain crowdsec-chain {
              type filter hook input priority filter; policy accept;
              ct state established,related accept
              ip saddr { ${jumphost.wanAddress4}, ${homeWan.cidrv4} } tcp dport 22 accept
              ip saddr @crowdsec-blacklists drop
            }
          }
          table ip6 crowdsec6 {
            set crowdsec6-blacklists {
              type ipv6_addr
              flags timeout
            }
            chain crowdsec6-chain {
              type filter hook input priority filter; policy accept;
              ct state established,related accept
              ip6 saddr { ${jumphost.wanAddress6}, ${homeWan.cidrv6} } tcp dport 22 accept
              ip6 saddr @crowdsec6-blacklists drop
            }
          }
        '';
        systemd = {
          services = {
            crowdsec-firewall-bouncer.after = lib.mkIf bootstrap [
              "crowdsec-firewall-bouncer-register.service"
            ];
            crowdsec-firewall-bouncer-register.serviceConfig = lib.mkIf bootstrap {
              ReadWritePaths = [ "/var/lib/crowdsec" ];
              StateDirectory = lib.mkForce "crowdsec-firewall-bouncer-register";
            };
            crowdsec-update-hub.serviceConfig.ExecStartPost = lib.mkForce "+systemctl try-restart crowdsec.service";
          };
          tmpfiles.settings."11-crowdsec-stub-capi" = lib.mkIf bootstrap {
            "${stateDir}/capi.yaml".f = {
              group = "crowdsec";
              mode = "0600";
              user = "crowdsec";
            };
          };
        };
      };
    };
}
