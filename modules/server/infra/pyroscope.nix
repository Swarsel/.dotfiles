{
  flake.modules.nixos.pyroscope =
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
          dir = "/var/lib/private/pyroscope";
          name = "pyroscope";
          port = 4040;
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
        homeServiceAddress
        homeWebProxy
        isHome
        nginxAccessRules
        webProxy
        wgProxyAccessRules
        ;

      memberlistPort = 7948;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          icon = "${self}/files/topology-images/${serviceName}.png";
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
            extra.extraConfig = {
              host = config.node.name;
              port = servicePort;
            };
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "ready";
            path = "/ready";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        services.${serviceName} = {
          enable = true;
          settings = {
            analytics.reporting_enabled = false;
            memberlist.bind_port = memberlistPort;
            metastore.address = "localhost:9098";
            multitenancy_enabled = false;
            pyroscopedb.data_path = "${serviceDir}/pyroscope";
            server = {
              grpc_listen_port = 9098;
              http_listen_address = "0.0.0.0";
              http_listen_port = servicePort;
              log_level = "warn";
            };
            storage = {
              backend = "filesystem";
              filesystem.dir = "${serviceDir}/data";
            };
            target = "all";
          };
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = serviceDir;
              mode = "0700";
            }
          ];
        };
        networking.firewall.allowedTCPPorts = [ servicePort ];
        systemd.services.${serviceName}.serviceConfig.RestartSec = lib.mkForce "60";
        nodes = lib.mkMerge [
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              extraConfig = wgProxyAccessRules;
              maxBody = 0;
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
          {
            ${globals.general.monitoringServer}.services.grafana.provision.datasources.settings.datasources = [
              {
                access = "proxy";
                name = "Pyroscope";
                type = "grafana-pyroscope-datasource";
                uid = "pyroscope";
                url = confLib.mkAlloyPushUrl {
                  domain = serviceDomain;
                  host = globals.general.monitoringServer;
                  path = "";
                  port = servicePort;
                };
              }
            ];
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
                  url = "${
                    confLib.mkAlloyPushUrl {
                      domain = serviceDomain;
                      host = alloyHost;
                      path = "";
                      port = servicePort;
                    }
                  }"
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

  ;
}
