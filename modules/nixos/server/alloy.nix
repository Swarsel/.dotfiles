{ lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "alloy"; port = 12345; })
    servicePort serviceName;
  inherit (confLib.static) isHome monitoringServer webProxy homeWebProxy inWgProxy inWgHome wgProxyMembers wgHomeMembers;

  otlpGrpcPort = 4317;
  otlpHttpPort = 4318;

  wgProxyHosts = globals.networks."${globals.wireguard.wgProxy.netConfigPrefix}-wgProxy".hosts;
  wgHomeHosts = globals.networks."${globals.wireguard.wgHome.netConfigPrefix}-wgHome".hosts;

  isCentral = config.node.name == monitoringServer;

  mimirDomain = globals.services.mimir.domain;
  lokiDomain = globals.services.loki.domain;
  tempoDomain = globals.services.tempo.domain;

  config-alloy =
    let
      mkPushUrl = domain: port: path:
        if isCentral then "http://127.0.0.1:${toString port}${path}"
        else if isHome then "http://${globals.networks.home-lan.vlans.services.hosts.${monitoringServer}.ipv4}:${toString port}${path}"
        else "https://${domain}${path}";

      targetsFor = host: targets:
        let netList = globals.monitoring.hostNetworks.${host} or [ ]; in
        map (t: removeAttrs t [ "network" ]) (lib.filter (t: builtins.elem t.network netList) targets);

      textfileDir = "/etc/alloy/textfiles";

      blackboxHostIp = host:
        # @ future me: yes, keep this to handle cloud hosts that are homeWgMembers
        if globals.hosts.${host}.isHome && builtins.elem host wgHomeMembers
        then wgHomeHosts.${host}.ipv4
        else if builtins.elem host wgProxyMembers
        then wgProxyHosts.${host}.ipv4
        else if builtins.elem host wgHomeMembers
        then wgHomeHosts.${host}.ipv4
        else null;

      mkBlackboxBlock =
        let
          mkAlloyMap = attrs:
            let
              esc = lib.replaceStrings [ ''\'' ''"'' ] [ ''\\'' ''\"'' ];
              pairs = lib.mapAttrsToList (k: v: ''"${k}" = "${esc v}"'') attrs;
            in
            "{${lib.concatStringsSep ", " pairs}}";

          mkAlloyTargets = items:
            "[\n" + lib.concatMapStrings (m: "      " + mkAlloyMap m + ",\n") items + "    ]";
        in
        { host, probeLabel, targets }:
        let
          hostIp = blackboxHostIp host;
          hostSlug = lib.replaceStrings [ "-" "." ] [ "_" "_" ] host;
        in
        ''

            discovery.relabel "blackbox_${probeLabel}_${hostSlug}" {
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
                replacement  = "${hostIp}:${toString globals.services.blackbox.extraConfig.port}"
              }
              rule {
                target_label = "probe_from"
                replacement  = "${host}"
              }
            }

            prometheus.scrape "blackbox_${probeLabel}_${hostSlug}" {
              targets      = discovery.relabel.blackbox_${probeLabel}_${hostSlug}.output
              metrics_path = "/probe"
              job_name     = "blackbox_${probeLabel}"
              forward_to   = [prometheus.remote_write.mimir.receiver]
            }
          '';

      reachableBlackboxHosts = lib.filter (h: blackboxHostIp h != null) globals.monitoring.blackboxHosts;

      httpTargets = lib.mapAttrsToList
        (name: cfg: {
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
        })
        globals.monitoring.http;

      pingTargets = lib.filter (t: t != null)
        (
          map
            (host:
              let
                cfg = globals.hosts.${host};
                inH = builtins.elem host wgHomeMembers;
                inP = builtins.elem host wgProxyMembers;
              in
              if cfg.isHome && inH then {
                __address__ = wgHomeHosts.${host}.ipv4;
                __param_module = "icmp";
                name = host;
                probe = "ping";
                network = "wgHome";
              }
              else if inP then {
                __address__ = wgProxyHosts.${host}.ipv4;
                __param_module = "icmp";
                name = host;
                probe = "ping";
                network = "wgProxy";
              }
              else if inH then {
                __address__ = wgHomeHosts.${host}.ipv4;
                __param_module = "icmp";
                name = host;
                probe = "ping";
                network = "wgHome";
              }
              else null
            )
            (lib.attrNames globals.hosts)
        ) ++ lib.mapAttrsToList
        (name: cfg: {
          __address__ = cfg.host;
          __param_module = "icmp";
          inherit name;
          probe = "ping";
          inherit (cfg) network;
        })
        globals.monitoring.ping;
    in
    ''
            logging {
              level  = "warn"
              format = "logfmt"
            }

            prometheus.exporter.unix "node" {${lib.optionalString isCentral ''

              textfile {
                directory = "${textfileDir}"
              }
            ''}}

            prometheus.scrape "node" {
              targets    = prometheus.exporter.unix.node.targets
              forward_to = [prometheus.remote_write.mimir.receiver]
              job_name   = "node"
            }
      ${lib.optionalString config.services.prometheus.exporters.smartctl.enable ''
            prometheus.scrape "smartctl" {
              targets         = [{"__address__" = "127.0.0.1:${toString globals.services.smartctl-exporter.extraConfig.port}"}]
              forward_to      = [prometheus.remote_write.mimir.receiver]
              job_name        = "smartctl"
              scrape_interval = "60s"
            }
      ''}${lib.optionalString  config.services.prometheus.exporters.zfs.enable ''
            prometheus.scrape "zfs" {
              targets    = [{"__address__" = "127.0.0.1:${toString globals.services.zfs-exporter.extraConfig.port}"}]
              forward_to = [prometheus.remote_write.mimir.receiver]
              job_name   = "zfs"
            }
      ''}
            prometheus.remote_write "mimir" {
              endpoint {
                url = "${mkPushUrl mimirDomain globals.services.mimir.extraConfig.port "/api/v1/push"}"
              }
              external_labels = {
                host = "${config.node.name}",
              }
            }

            loki.relabel "journal" {
              forward_to = []
              rule {
                source_labels = ["__journal__systemd_unit"]
                target_label  = "unit"
              }
              rule {
                source_labels = ["__journal_priority_keyword"]
                target_label  = "level"
              }
            }

            loki.source.journal "journal" {
              max_age       = "12h"
              relabel_rules = loki.relabel.journal.rules
              forward_to    = [loki.write.central.receiver]
              labels        = {
                host = "${config.node.name}",
                job  = "systemd-journal",
              }
            }

            loki.write "central" {
              endpoint {
                url = "${mkPushUrl lokiDomain globals.services.loki.extraConfig.port "/loki/api/v1/push"}"
              }
            }

            otelcol.receiver.otlp "local" {
              grpc { endpoint = "127.0.0.1:${toString otlpGrpcPort}" }
              http { endpoint = "127.0.0.1:${toString otlpHttpPort}" }

              output {
                traces = [otelcol.exporter.otlphttp.tempo.input]
              }
            }

            otelcol.exporter.otlphttp "tempo" {
              client {
                endpoint = "${mkPushUrl tempoDomain globals.services.tempo.extraConfig.port ""}"
              }
            }
    ''
    + lib.optionalString isCentral (
      lib.concatMapStrings
        (host:
          let ts = targetsFor host httpTargets; in
          lib.optionalString (ts != [ ]) (mkBlackboxBlock {
            inherit host;
            probeLabel = "http";
            targets = ts;
          })
        )
        reachableBlackboxHosts
      +
      lib.concatMapStrings
        (host:
          let ts = targetsFor host pingTargets; in
          lib.optionalString (ts != [ ]) (mkBlackboxBlock {
            inherit host;
            probeLabel = "ping";
            targets = ts;
          })
        )
        reachableBlackboxHosts
    );
in
{
  config = {
    swarselsystems.enabledServerModules = [ serviceName ];

    globals = {
      services.${serviceName}.extraConfig = {
        httpPort = servicePort;
        inherit otlpGrpcPort otlpHttpPort;
      };
      monitoring.hostNetworks.${config.node.name} = [ "local-${config.node.name}" ]
        ++ lib.optional inWgHome "wgHome"
        ++ lib.optional inWgProxy "wgProxy"
        ++ lib.optional
        (globals.hosts.${config.node.name}.wanAddress4 != null
          || globals.hosts.${config.node.name}.wanAddress6 != null) "internet";
    };

    networking.hosts =
      let
        proxyIp =
          if isHome && inWgHome
          then wgHomeHosts.${homeWebProxy}.ipv4
          else if inWgProxy
          then wgProxyHosts.${webProxy}.ipv4
          else null;
      in
      lib.optionalAttrs (proxyIp != null) {
        ${proxyIp} = [ mimirDomain lokiDomain tempoDomain ];
      };

    environment = {
      etc = {
        "alloy/config.alloy".text = config-alloy;
        "alloy/textfiles/host_expected.prom" = lib.mkIf isCentral {
          text = lib.concatStrings (map
            (h: ''host_expected{host="${h}"} 1
                '')
            (lib.attrNames globals.hosts));
        };
      };
      persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
        directories = [{ directory = "/var/lib/private/alloy"; mode = "0700"; }];
      };
    };

    services.${serviceName} = {
      enable = true;
      extraFlags = [ "--server.http.listen-addr=127.0.0.1:${toString servicePort}" ];
    };

    systemd.services.alloy.serviceConfig.RestartSec = lib.mkForce "60";

  };
}
