{
  flake.modules.nixos.crowdsec =
    {
      lib,
      pkgs,
      config,
      globals,
      confLib,
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

        globals.monitoring.http = confLib.mkHttpMonitoring {
          serviceName = "crowdsec";
          servicePort = lapiPort;
          path = "/v1/decisions";
          expectedStatus = 403;
        };

        topology.self.services.${serviceName} = {
          name = lib.swarselsystems.toCapitalized serviceName;
        };

        users = {
          persistentIds.crowdsec = confLib.mkIds 946;
          users.crowdsec.extraGroups = [ "nginx" ];
        };

        sops.secrets = lib.mkIf (!bootstrap) {
          crowdsec-lapi = {
            inherit sopsFile;
            owner = "crowdsec";
            group = "crowdsec";
            mode = "0400";
          };
          crowdsec-capi = {
            inherit sopsFile;
            owner = "crowdsec";
            group = "crowdsec";
            mode = "0400";
          };
          crowdsec-bouncer-key = {
            inherit sopsFile;
            owner = "crowdsec";
            group = "crowdsec";
            mode = "0400";
          };
        };

        services.crowdsec = {
          enable = true;
          autoUpdateService = true;

          settings = {
            general.api.server = {
              enable = true;
              listen_uri = "127.0.0.1:8089";
            };
            lapi.credentialsFile =
              if bootstrap then "/var/lib/crowdsec/state/lapi.yaml" else config.sops.secrets.crowdsec-lapi.path;
            capi.credentialsFile =
              if bootstrap then "/var/lib/crowdsec/state/capi.yaml" else config.sops.secrets.crowdsec-capi.path;
            simulation.simulation = false;
          };

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
                source = "file";
                filenames = [
                  "/var/log/nginx/access.log"
                  "/var/log/nginx/error.log"
                ];
                labels.type = "nginx";
              }
              {
                source = "journalctl";
                journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
                labels.type = "syslog";
              }
            ];

            parsers.s02Enrich = [
              {
                name = "swarsel/trusted-cidrs";
                description = "Fallback in case base allowlist ever changes";
                whitelist = {
                  reason = "Trusted internal networks";
                  cidr = [
                    "10.0.0.0/8"
                    "172.16.0.0/12"
                    "192.168.0.0/16"
                    "fc00::/7"
                  ];
                };
              }
              {
                name = "swarsel/attic-cache";
                description = "Don't count cache requests as probes";
                whitelist = {
                  reason = "Attic binary cache lookups; misses are expected 404s";
                  expression = [
                    "evt.Meta.http_path matches `\\.nar(info)?$`"
                  ];
                };
              }
            ]
            ++ lib.optional (allowlistIps != [ ] || allowlistCidrs != [ ] || allowlistAs != [ ]) {
              name = "swarsel/allowlist";
              description = "Don't ban trusted addresses";
              whitelist = {
                reason = "Personal home addresses and trusted work AS";
                ip = allowlistIps;
                cidr = allowlistCidrs;
                expression = map (asn: "evt.Enriched.ASNumber == '${toString asn}'") allowlistAs;
              };
            };

            postOverflows.s01Whitelist = [
              {
                name = "swarsel/trusted-hosts";
                description = "Allow (but track) host addresses";
                whitelist = {
                  reason = "Trusted host WAN addresses";
                  ip = trustedWanAddresses;
                };
              }
            ];
          };
        };

        services.crowdsec-firewall-bouncer = {
          enable = true;
          createRulesets = false;
          registerBouncer.enable = bootstrap;
          secrets.apiKeyPath = lib.mkIf (!bootstrap) config.sops.secrets.crowdsec-bouncer-key.path;
        };

        systemd = {
          tmpfiles.settings."11-crowdsec-stub-capi" = lib.mkIf bootstrap {
            "/var/lib/crowdsec/state/capi.yaml".f = {
              mode = "0600";
              user = "crowdsec";
              group = "crowdsec";
            };
          };

          services = {
            crowdsec-firewall-bouncer-register.serviceConfig = lib.mkIf bootstrap {
              StateDirectory = lib.mkForce "crowdsec-firewall-bouncer-register";
              ReadWritePaths = [ "/var/lib/crowdsec" ];
            };

            crowdsec-firewall-bouncer.after = lib.mkIf bootstrap [
              "crowdsec-firewall-bouncer-register.service"
            ];

            crowdsec-update-hub.serviceConfig.ExecStartPost = lib.mkForce "+systemctl try-restart crowdsec.service";
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

        environment = {
          etc = {
            "crowdsec/config.yaml" = lib.mkIf bootstrap {
              source = (pkgs.formats.yaml { }).generate "crowdsec.yaml" config.services.crowdsec.settings.general;
            };
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
          };
          persistence."/persist" = lib.mkIf config.swarselsystems.isImpermanence {
            directories = [
              {
                directory = "/var/lib/crowdsec";
                user = "crowdsec";
                group = "crowdsec";
                mode = "0750";
              }
            ];
          };
        };
      };
    }

  ;
}
