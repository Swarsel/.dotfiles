{
  flake.modules.nixos.blackbox =
    {
      lib,
      config,
      globals,
      confLib,
      pkgs,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "blackbox";
          port = 9115;
        })
        servicePort
        serviceName
        ;

      mkHttpModule = cfg: {
        prober = "http";
        timeout = "10s";
        http = {
          method = "GET";
          follow_redirects = true;
          preferred_ip_protocol = "ip4";
          tls_config.insecure_skip_verify = true;
          valid_status_codes = [ cfg.expectedStatus ];
        }
        // lib.optionalAttrs (cfg.expectedBodyRegex != null) {
          fail_if_body_not_matches_regexp = [ cfg.expectedBodyRegex ];
        }
        // lib.optionalAttrs (cfg.failIfBodyMatchesRegex != null) {
          fail_if_body_matches_regexp = [ cfg.failIfBodyMatchesRegex ];
        }
        // lib.optionalAttrs (cfg.hostHeader != null) {
          headers.Host = cfg.hostHeader;
        };
      };

      blackboxConfig = pkgs.writeText "blackbox.yml" (
        builtins.toJSON {
          modules = {
            icmp = {
              prober = "icmp";
              timeout = "5s";
              icmp.preferred_ip_protocol = "ip4";
            };
          }
          // lib.mapAttrs' (
            name: cfg: lib.nameValuePair "http_${name}" (mkHttpModule cfg)
          ) globals.monitoring.http;
        }
      );

      targetsFor =
        host: targets:
        let
          netList = globals.monitoring.hostNetworks.${host} or [ ];
        in
        map (t: removeAttrs t [ "network" ]) (lib.filter (t: builtins.elem t.network netList) targets);

      mkBlackboxBlock =
        let
          mkAlloyMap =
            attrs:
            let
              esc = lib.replaceStrings [ ''\'' ''"'' ] [ ''\\'' ''\"'' ];
              pairs = lib.mapAttrsToList (k: v: ''"${k}" = "${esc v}"'') attrs;
            in
            "{${lib.concatStringsSep ", " pairs}}";

          mkAlloyTargets =
            items: "[\n" + lib.concatMapStrings (m: "      " + mkAlloyMap m + ",\n") items + "    ]";
        in
        { probeLabel, targets }:
        ''

          discovery.relabel "blackbox_${probeLabel}" {
            targets = ${mkAlloyTargets targets}

            rule {
              source_labels = ["__address__"]
              target_label  = "__param_target"
            }
            rule {
              source_labels = ["__param_target"]
              target_label  = "instance"
            }
            rule {
              target_label = "__address__"
              replacement  = "127.0.0.1:${toString servicePort}"
            }
            rule {
              target_label = "probe_from"
              replacement  = "${config.node.name}"
            }
          }

          prometheus.scrape "blackbox_${probeLabel}" {
            targets      = discovery.relabel.blackbox_${probeLabel}.output
            metrics_path = "/probe"
            job_name     = "blackbox_${probeLabel}"
            forward_to   = [prometheus.remote_write.mimir.receiver]
          }
        '';

      httpTargets = targetsFor config.node.name (
        lib.mapAttrsToList (
          name: cfg:
          {
            __address__ = cfg.url;
            __param_module = "http_${name}";
            inherit name;
            probe = "http";
            inherit (cfg) network;
          }
          // lib.optionalAttrs (cfg.expectedBodyRegex != null) {
            expected_body_regex = cfg.expectedBodyRegex;
          }
          // lib.optionalAttrs (cfg.failIfBodyMatchesRegex != null) {
            fail_if_body_matches_regex = cfg.failIfBodyMatchesRegex;
          }
        ) globals.monitoring.http
      );

      pingTargets = targetsFor config.node.name (
        lib.mapAttrsToList (name: cfg: {
          __address__ = cfg.host;
          __param_module = "icmp";
          inherit name;
          probe = "ping";
          inherit (cfg) network;
        }) globals.monitoring.ping
      );
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];

        globals.services.${serviceName}.extraConfig.port = servicePort;

        topology.self.services.${serviceName} = {
          name = "blackbox-exporter";
          icon = "services.prometheus";
        };

        services.prometheus.exporters.blackbox = {
          enable = true;
          port = servicePort;
          listenAddress = "127.0.0.1";
          configFile = blackboxConfig;
        };

        environment.etc."alloy/config.alloy".text = lib.mkIf config.services.alloy.enable (
          lib.mkAfter (
            lib.optionalString (httpTargets != [ ]) (mkBlackboxBlock {
              probeLabel = "http";
              targets = httpTargets;
            })
            + lib.optionalString (pingTargets != [ ]) (mkBlackboxBlock {
              probeLabel = "ping";
              targets = pingTargets;
            })
          )
        );

        nodes.${globals.general.monitoringServer}.services.grafana.provision.alerting.rules.settings.groups =
          let
            defaultProbeFor = "3m";
            probesByFor = lib.foldlAttrs (
              acc: name: cfg:
              let
                forDuration = if cfg.alertFor != null then cfg.alertFor else defaultProbeFor;
              in
              acc // { ${forDuration} = (acc.${forDuration} or [ ]) ++ [ name ]; }
            ) { } globals.monitoring.http;
            mkProbeRule =
              forDuration: names:
              let
                selector = ''probe="http",name=~"${lib.concatStringsSep "|" names}"'';
              in
              confLib.mkGrafanaAlertRule {
                uid =
                  if forDuration == defaultProbeFor then "http_probe_failed" else "http_probe_failed_${forDuration}";
                title = "HTTP probe failed${
                  lib.optionalString (forDuration != defaultProbeFor) " (after ${forDuration})"
                }";
                expr = "min by (name) (probe_success{${selector}}) or on(name) (probe_expected{${selector}} * 0)";
                inherit forDuration;
                summary = "Blackbox HTTP probe for {{ $labels.name }} has been failing";
              };
          in
          [
            {
              orgId = 1;
              name = "blackbox";
              folder = "Infrastructure";
              interval = "1m";
              rules = lib.mapAttrsToList mkProbeRule probesByFor;
            }
          ];
      };
    }

  ;
}
