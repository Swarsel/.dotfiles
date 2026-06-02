{ self, lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen {
    name = "pyroscope";
    port = 4040;
    dir = "/var/lib/private/pyroscope";
  }) servicePort serviceName serviceDir serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome webProxy homeWebProxy homeServiceAddress nginxAccessRules wgProxyAccessRules;

  memberlistPort = 7948;
in
{
  config = {
    swarselsystems.enabledServerModules = [ serviceName ];

    topology.self.services.${serviceName} = {
      name = lib.swarselsystems.toCapitalized serviceName;
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

    globals = {
      networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; extra.extraConfig = { port = servicePort; host = config.node.name; }; };
      monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; path = "/ready"; expectedBodyRegex = "ready"; };
      dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
    };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = serviceDir; mode = "0700"; }];
    };

    services.${serviceName} = {
      enable = true;
      settings = {
        target = "all";
        multitenancy_enabled = false;
        analytics.reporting_enabled = false;
        server = {
          http_listen_address = "0.0.0.0";
          http_listen_port = servicePort;
          grpc_listen_port = 9098;
          log_level = "warn";
        };
        storage = {
          backend = "filesystem";
          filesystem.dir = "${serviceDir}/data";
        };
        pyroscopedb.data_path = "${serviceDir}/pyroscope";
        memberlist.bind_port = memberlistPort;
      };
    };

    systemd.services.${serviceName}.serviceConfig.RestartSec = lib.mkForce "60";

    nodes = lib.mkMerge [
      {
        ${webProxy}.services.nginx = confLib.genNginx {
          inherit serviceAddress servicePort serviceDomain serviceName;
          maxBody = 0;
          extraConfig = wgProxyAccessRules;
        };
        ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx {
          inherit servicePort serviceDomain serviceName;
          serviceAddress = homeServiceAddress;
          maxBody = 0;
          extraConfig = nginxAccessRules;
        });
        ${globals.general.monitoringServer}.services.grafana.provision.datasources.settings.datasources = [{
          name = "Pyroscope";
          uid = "pyroscope";
          type = "grafana-pyroscope-datasource";
          access = "proxy";
          url = confLib.mkAlloyPushUrl {
            host = globals.general.monitoringServer;
            domain = serviceDomain;
            port = servicePort;
            path = "";
          };
        }];
      }
      (lib.genAttrs (lib.attrNames globals.services.alloy.extraConfig.clients) (alloyHost: {
        environment.etc."alloy/config.alloy".text = lib.mkAfter ''
          discovery.process "all" {
            refresh_interval = "30s"
            discover_config {
              cwd          = false
              exe          = true
              commandline  = false
              username     = false
              uid          = false
              container_id = true
            }
          }

          discovery.relabel "process" {
            targets = discovery.process.all.targets

            rule {
              source_labels = ["__meta_process_exe"]
              regex         = "(?:.*/)?([^/]+)"
              target_label  = "service_name"
            }
            rule {
              source_labels = ["__meta_process_cgroup_id"]
              regex         = ".*/([^/]+)\\.service"
              target_label  = "service_name"
            }
          }

          pyroscope.ebpf "auto" {
            targets           = discovery.relabel.process.output
            forward_to        = [pyroscope.write.central.receiver]
            off_cpu_threshold = 0.01
          }

          pyroscope.write "central" {
            endpoint {
              url = "${confLib.mkAlloyPushUrl {
                host = alloyHost;
                domain = serviceDomain;
                port = servicePort;
                path = "";
              }}"
            }
            external_labels = {
              host = "${alloyHost}",
            }
          }
        '';
      }))
    ];
  };
}
