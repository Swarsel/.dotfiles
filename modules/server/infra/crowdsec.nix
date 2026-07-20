{
  flake.modules.nixos.crowdsec =
    {
      config,
      lib,
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      inherit (config.swarselsystems) sopsFile;
      inherit
        (confLib.gen {
          name = "crowdsec";
        })
        serviceName
        ;
      bootstrap = config.swarselsystems.crowdsecBootstrap;
      jumphost = globals.general.jumphost or null;
      jumphostWan4 = if jumphost != null then globals.hosts.${jumphost}.wanAddress4 or null else null;
      jumphostWan6 = if jumphost != null then globals.hosts.${jumphost}.wanAddress6 or null else null;
      trustedWanAddresses = lib.filter (a: a != null) (
        lib.concatMap (h: [
          (h.wanAddress4 or null)
          (h.wanAddress6 or null)
        ]) (lib.attrValues globals.hosts)
      );
      allowlistIps = config.repo.secrets.local.crowdsec.allowlistIps or [ ];
      allowlistCidrs = config.repo.secrets.local.crowdsec.allowlistCidrs or [ ];
      allowlistAs = config.repo.secrets.local.crowdsec.allowlistAs or [ ];
      lapiPort = lib.toInt (
        lib.last (lib.splitString ":" config.services.crowdsec.settings.general.api.server.listen_uri)
      );
    in
    {
      options.swarselsystems.crowdsecBootstrap = lib.mkEnableOption "create lapi, capi, and bouncer api key. afterwards they can be added to sops and this disabled";
      config = {
        swarselsystems.enabledServerModules = [ "crowdsec" ];
        topology.self.services.${serviceName}.name = lib.swarselsystems.toCapitalized serviceName;
        globals.monitoring.http = confLib.mkHttpMonitoring {
          expectedStatus = 403;
          path = "/v1/decisions";
          serviceName = "crowdsec";
          servicePort = lapiPort;
        };
        sops.secrets = lib.mkIf (!bootstrap) {
          crowdsec-bouncer-key = {
            inherit sopsFile;
            group = "crowdsec";
            mode = "0400";
            owner = "crowdsec";
          };
          crowdsec-capi = {
            inherit sopsFile;
            group = "crowdsec";
            mode = "0400";
            owner = "crowdsec";
          };
          crowdsec-lapi = {
            inherit sopsFile;
            group = "crowdsec";
            mode = "0400";
            owner = "crowdsec";
          };
        };
        users = {
          users.crowdsec.extraGroups = [ "nginx" ];
          persistentIds.crowdsec = confLib.mkIds 946;
        };
        services = {
          crowdsec = {
            enable = true;
            autoUpdateService = true;
            hub.collections = [
              "crowdsecurity/linux"
              "crowdsecurity/nginx"
              "crowdsecurity/base-http-scenarios"
              "crowdsecurity/http-cve"
              "crowdsecurity/sshd"
            ];
            localConfig = {
              acquisitions = [
                {
                  filenames = [
                    "/var/log/nginx/access.log"
                    "/var/log/nginx/error.log"
                  ];
                  labels.type = "nginx";
                  source = "file";
                }
                {
                  journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
                  labels.type = "syslog";
                  source = "journalctl";
                }
              ];

              parsers.s02Enrich = [
                {
                  description = "Fallback in case base allowlist ever changes";
                  name = "swarsel/trusted-cidrs";
                  whitelist = {
                    cidr = [
                      "10.0.0.0/8"
                      "172.16.0.0/12"
                      "192.168.0.0/16"
                      "fc00::/7"
                    ];
                    reason = "Trusted internal networks";
                  };
                }
                {
                  description = "Don't count cache requests as probes";
                  name = "swarsel/attic-cache";
                  whitelist = {
                    expression = [
                      "evt.Meta.http_path matches `\\.nar(info)?$`"
                    ];
                    reason = "Attic binary cache lookups; misses are expected 404s";
                  };
                }
              ]
              ++ lib.optional (allowlistIps != [ ] || allowlistCidrs != [ ] || allowlistAs != [ ]) {
                description = "Don't ban trusted addresses";
                name = "swarsel/allowlist";
                whitelist = {
                  cidr = allowlistCidrs;
                  expression = map (asn: "evt.Enriched.ASNumber == '${toString asn}'") allowlistAs;
                  ip = allowlistIps;
                  reason = "Personal home addresses and trusted work AS";
                };
              };

              postOverflows.s01Whitelist = [
                {
                  description = "Allow (but track) host addresses";
                  name = "swarsel/trusted-hosts";
                  whitelist = {
                    ip = trustedWanAddresses;
                    reason = "Trusted host WAN addresses";
                  };
                }
              ];
            };
            settings = {
              capi.credentialsFile =
                if bootstrap then "/var/lib/crowdsec/state/capi.yaml" else config.sops.secrets.crowdsec-capi.path;
              general.api.server = {
                enable = true;
                listen_uri = "127.0.0.1:8089";
              };
              lapi.credentialsFile =
                if bootstrap then "/var/lib/crowdsec/state/lapi.yaml" else config.sops.secrets.crowdsec-lapi.path;
              simulation.simulation = false;
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
          etc = {
            "alloy/config.alloy".text = lib.mkIf config.services.alloy.enable (
              lib.mkAfter ''
                prometheus.scrape "crowdsec" {
                  targets         = [{"__address__" = "127.0.0.1:${toString config.services.crowdsec.settings.general.prometheus.listen_port}"}]
                  forward_to      = [prometheus.remote_write.mimir.receiver]
                  job_name        = "crowdsec"
                  scrape_interval = "30s"
                }
              ''
            );
            "crowdsec/config.yaml" = lib.mkIf bootstrap {
              source = (pkgs.formats.yaml { }).generate "crowdsec.yaml" config.services.crowdsec.settings.general;
            };
          };
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
              ${lib.optionalString (jumphostWan4 != null) "ip saddr ${jumphostWan4} tcp dport 22 accept"}
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
              ${lib.optionalString (jumphostWan6 != null) "ip6 saddr ${jumphostWan6} tcp dport 22 accept"}
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
            "/var/lib/crowdsec/state/capi.yaml".f = {
              group = "crowdsec";
              mode = "0600";
              user = "crowdsec";
            };
          };
        };
      };
    }

  ;
}
