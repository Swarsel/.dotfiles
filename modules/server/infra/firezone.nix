{
  # this one still supports provision, name is not nixpgks-[...] on purpose to avoid adding to the overlay
  flake-file.inputs.nixpkgsFirezoneProvisioned = {
    url = "github:nixos/nixpkgs/a799d3e3886da994fa307f817a6bc705ae538eeb?narHash=sha256-3av0pIjlOWQ6rDbNOmpUSvbNnJkGORQKKjb4LtCZsIY%3D";
  };

  flake.modules.nixos.firezone =
    {
      self,
      inputs,
      config,
      lib,
      pkgs,
      confLib,
      globals,
      nodes,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/private/firezone";
          name = "firezone";
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
        serviceDomain
        serviceName
        ;
      inherit (confLib.static)
        homeProxy
        homeProxyIf
        homeServiceAddress
        homeWebProxy
        idmServer
        isHome
        isProxied
        monitoringServer
        nginxAccessRules
        webProxy
        webProxyIf
        ;
      inherit (config.swarselsystems) sopsFile;

      apiPort = 8081;
      webPort = 8080;
      relayPort = 3478;
      relayHealthPort = 8082;
      relayStunHealthPort = 8083;
      domainPort = 9003;

      firezoneTargetVLANs = [
        "services"
        "home"
        "devices"
      ];
      firezoneTargetZones = map (v: "vlan-${v}") firezoneTargetVLANs;

      homeServices = lib.attrNames (lib.filterAttrs (_: serviceCfg: serviceCfg.isHome) globals.services);
      homeDomains = map (name: globals.services.${name}.domain) homeServices;
      smbDomain = "smb.${globals.domains.main}";
      vlanCidrResources = lib.listToAttrs (
        lib.concatMap (vlan: [
          {
            name = "home.vlan-${vlan}.v4";
            value = {
              address = globals.networks.home-lan.vlans.${vlan}.cidrv4;
              gatewayGroups = [ "home" ];
              name = "home.vlan-${vlan}.v4";
              type = "cidr";
            };
          }
          {
            name = "home.vlan-${vlan}.v6";
            value = {
              address = globals.networks.home-lan.vlans.${vlan}.cidrv6;
              gatewayGroups = [ "home" ];
              name = "home.vlan-${vlan}.v6";
              type = "cidr";
            };
          }
        ]) firezoneTargetVLANs
      );
      allow = group: resource: {
        "${group}@${resource}" = {
          inherit group resource;
          description = "Allow ${group} access to ${resource}";
        };
      };

      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";

      disabledFirezoneModules = [
        "gateway.nix"
        "relay.nix"
        "server.nix"
        "gui-client.nix"
        "headless-client.nix"
      ];
      disabledFirezoneModule = name: "services/networking/firezone/${name}";
    in
    {
      imports = map (
        name: "${inputs.nixpkgsFirezoneProvisioned}/nixos/modules/${disabledFirezoneModule name}"
      ) disabledFirezoneModules;
      config = {
        swarselsystems.enabledServerModules = [ "firezone" ];
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
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = lib.mkMerge [
            (confLib.mkHttpMonitoring {
              expectedBodyRegex = ''"status":"ok"'';
              path = "/healthz";
              serviceName = "firezone-server-domain";
              servicePort = config.services.firezone.server.domain.settings.HEALTHZ_PORT;
            })
            (confLib.mkHttpMonitoring {
              expectedBodyRegex = ''"status":"ok"'';
              path = "/healthz";
              serviceName = "firezone-server-web";
              servicePort = config.services.firezone.server.web.settings.HEALTHZ_PORT;
            })
            (confLib.mkHttpMonitoring {
              expectedBodyRegex = ''"status":"ok"'';
              path = "/healthz";
              serviceName = "firezone-server-api";
              servicePort = config.services.firezone.server.api.settings.HEALTHZ_PORT;
            })
            (confLib.mkHttpMonitoring {
              path = "/healthz";
              serviceName = "firezone-relay";
              servicePort = relayHealthPort;
            })
            (confLib.mkHttpMonitoring {
              expectedBodyRegex = ''"status":"ok"'';
              path = "/healthz";
              serviceName = "firezone-relay-stun";
              servicePort = relayStunHealthPort;
            })
            {
              firezone-gateway = {
                network = "local-${homeProxy}";
                url = "http://127.0.0.1:${toString webPort}/healthz";
              };
            }
          ];
          networks = {
            ${homeProxyIf}.hosts = lib.mkIf isHome {
              ${config.node.name}.firewallRuleForNode.${homeWebProxy} = {
                allowedTCPPorts = [
                  apiPort
                  webPort
                  domainPort
                ];
                allowedUDPPortRanges = [
                  {
                    from = config.services.firezone.relay.lowestPort;
                    to = config.services.firezone.relay.highestPort;
                  }
                ];
                allowedUDPPorts = [ relayPort ];
              };
            };
            ${webProxyIf}.hosts = lib.mkIf isProxied {
              ${config.node.name}.firewallRuleForNode.${webProxy} = {
                allowedTCPPorts = [
                  apiPort
                  webPort
                  domainPort
                ];
                allowedUDPPortRanges = [
                  {
                    from = config.services.firezone.relay.lowestPort;
                    to = config.services.firezone.relay.highestPort;
                  }
                ];
                allowedUDPPorts = [ relayPort ];
              };
            };
          };
        };
        sops = {
          secrets = {
            firezone-adapter-config = {
              inherit sopsFile;
              mode = "0440";
            };
            firezone-relay-token = {
              inherit sopsFile;
              mode = "0400";
            };
            firezone-smtp-password = {
              inherit sopsFile;
              mode = "0440";
            };
            kanidm-firezone = {
              mode = "0400";
              sopsFile = kanidmSopsFile;
            };
          };
        };
        services.firezone = {
          relay = {
            inherit (config.node) name;
            enable = true;
            package = pkgs.firezone-relay;
            apiUrl = "wss://${serviceDomain}/api/";
            openFirewall = lib.mkIf (!isProxied) true;
            port = relayPort;
            publicIpv4 = proxyAddress4;
            publicIpv6 = proxyAddress6;
            tokenFile = config.sops.secrets.firezone-relay-token.path;
          };
          server = {
            enable = true;
            api = {
              package = pkgs.firezone-server-api;
              address = "0.0.0.0";
              externalUrl = "https://${serviceDomain}/api/";
              port = apiPort;
            };
            domain = {
              package = pkgs.firezone-server-domain;
              settings.ERLANG_DISTRIBUTION_PORT = domainPort;
            };
            enableLocalDB = true;
            provision = {
              enable = true;
              accounts.main = {
                actors.admin = {
                  email = "admin@${globals.domains.main}";
                  name = "Admin";
                  type = "account_admin_user";
                };
                auth.oidc =
                  let
                    client_id = "firezone";
                  in
                  {
                    adapter = "openid_connect";
                    adapter_config = {
                      inherit client_id;
                      clientSecretFile = config.sops.secrets.kanidm-firezone.path;
                      discovery_document_uri = "https://${globals.services.kanidm.domain}/oauth2/openid/${client_id}/.well-known/openid-configuration";
                      response_type = "code";
                      scope = "openid email profile";
                    };
                    name = "Kanidm";
                  };
                gatewayGroups.home.name = "Home";
                groups.anyone = {
                  members = [
                    "admin"
                  ];
                  name = "anyone";
                };
                name = "Home";
                policies =
                  { }
                  // lib.mergeAttrsList (
                    lib.concatMap (resource: [
                      (allow "everyone" resource)
                      (allow "anyone" resource)
                    ]) (lib.attrNames vlanCidrResources)
                  )
                  // lib.mergeAttrsList (map (domain: allow "everyone" domain) homeDomains)
                  // lib.mergeAttrsList (map (domain: allow "anyone" domain) homeDomains)
                  // (allow "everyone" smbDomain)
                  // (allow "anyone" smbDomain);
                relayGroups.relays.name = "Relays";
                resources =
                  lib.genAttrs homeDomains (domain: {
                    address = domain;
                    filters = [
                      { protocol = "icmp"; }
                      {
                        ports = [
                          443
                          80
                        ];
                        protocol = "tcp";
                      }
                      {
                        ports = [ 443 ];
                        protocol = "udp";
                      }
                    ];
                    gatewayGroups = [ "home" ];
                    name = domain;
                    type = "dns";
                  })
                  // vlanCidrResources
                  // {
                    ${smbDomain} = {
                      address = smbDomain;
                      filters = [
                        { protocol = "icmp"; }
                        {
                          ports = [
                            445
                            139
                          ];
                          protocol = "tcp";
                        }
                      ];
                      gatewayGroups = [ "home" ];
                      name = smbDomain;
                      type = "dns";
                    };
                  };
              };
            };
            smtp = {
              inherit (config.repo.secrets.local.firezone.mail) from username;
              host = globals.services.mailserver.domain;
              implicitTls = true;
              passwordFile = config.sops.secrets.firezone-smtp-password.path;
              port = 465;
            };
            web = {
              package = pkgs.firezone-server-web;
              address = "0.0.0.0";
              externalUrl = "https://${serviceDomain}/";
              port = webPort;
            };
          };
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            mode = "0700";
          }
          {
            directory = "${serviceDir}-relay";
            mode = "0700";
          }
        ];
        systemd.services = lib.mkMerge [
          (lib.genAttrs
            [
              "firezone-server-web"
              "firezone-server-api"
              "firezone-server-domain"
            ]
            (_: {
              serviceConfig.RestartSec = lib.mkForce 30;
              startLimitBurst = 10;
              startLimitIntervalSec = 600;
            })
          )
          {
            firezone-relay.environment.HEALTH_CHECK_ADDR = "0.0.0.0:${toString relayHealthPort}";
            firezone-relay-stun-healthcheck = {
              after = [ "firezone-relay.service" ];
              description = "STUN responsiveness healthcheck for the Firezone relay";
              serviceConfig = {
                DynamicUser = true;
                ExecStart = "${lib.getExe pkgs.python3} ${pkgs.writeText "firezone-relay-stun-healthcheck.py" ''
                  import http.server
                  import os
                  import socket
                  import struct


                  class Handler(http.server.BaseHTTPRequestHandler):
                      def do_GET(self):
                          req = struct.pack("!HHI", 1, 0, 0x2112A442) + os.urandom(12)
                          sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                          sock.settimeout(3)
                          try:
                              sock.sendto(req, ("127.0.0.1", ${toString relayPort}))
                              resp = sock.recvfrom(2048)[0]
                              ok = resp[0:2] == b"\x01\x01" and resp[8:20] == req[8:20]
                          except OSError:
                              ok = False
                          finally:
                              sock.close()
                          body = b'{"status":"ok"}' if ok else b'{"status":"unresponsive"}'
                          self.send_response(200 if ok else 503)
                          self.send_header("Content-Type", "application/json")
                          self.send_header("Content-Length", str(len(body)))
                          self.end_headers()
                          self.wfile.write(body)

                      def log_message(self, fmt, *args):
                          pass


                  http.server.ThreadingHTTPServer(
                      ("127.0.0.1", ${toString relayStunHealthPort}), Handler
                  ).serve_forever()
                ''}";
                Restart = "always";
                RestartSec = "5s";
              };
              wantedBy = [ "multi-user.target" ];
            };
          }
        ];
        nodes = lib.mkMerge [
          (
            let
              genNginx = toAddress: extraConfig: {
                upstreams = {
                  ${serviceName} = {
                    servers."${toAddress}:${builtins.toString webPort}" = { };
                  };
                  "${serviceName}-api" = {
                    servers."${toAddress}:${builtins.toString apiPort}" = { };
                  };
                };
                virtualHosts = {
                  ${serviceDomain} = {
                    inherit extraConfig;
                    acmeRoot = null;
                    forceSSL = true;
                    locations = {
                      "/" = {
                        # The trailing slash is important to strip the location prefix from the request
                        proxyPass = "http://${serviceName}/";
                        proxyWebsockets = true;
                      };
                      "/api/" = {
                        # The trailing slash is important to strip the location prefix from the request
                        proxyPass = "http://${serviceName}-api/";
                        proxyWebsockets = true;
                      };
                    };
                    useACMEHost = globals.domains.main;
                  };
                };
              };
            in
            lib.mkMerge [
              {
                ${homeProxy} =
                  let
                    nodeCfg = nodes.${homeProxy}.config;
                    nodePkgs = nodes.${homeProxy}.pkgs;
                  in
                  {
                    topology.self.services."${serviceName}-gateway" = {
                      icon = "${self}/files/topology-images/${serviceName}.png";
                      name = lib.swarselsystems.toCapitalized "${serviceName} Gateway";
                    };
                    sops.secrets.firezone-gateway-token = {
                      inherit (nodeCfg.swarselsystems) sopsFile;
                      mode = "0400";
                    };
                    services.firezone.gateway = {
                      # logLevel = "trace";
                      inherit (nodeCfg.node) name;
                      enable = true;
                      package = nodePkgs.stable25_05.firezone-gateway; # newer versions of firezone-gateway are not compatible with server package
                      apiUrl = "wss://${globals.services.firezone.domain}/api/";
                      tokenFile = nodeCfg.sops.secrets.firezone-gateway-token.path;
                    };
                    boot.kernel.sysctl = {
                      "net.core.rmem_max" = 134217728;
                      "net.core.wmem_max" = 16777216;
                    };
                    environment.persistence."/persist".directories = lib.mkIf nodeCfg.swarselsystems.isImpermanence [
                      {
                        directory = "${serviceDir}-gateway";
                        mode = "0700";
                      }
                    ];
                    networking.nftables = {
                      chains.postrouting = {
                        masquerade-firezone = {
                          after = [ "hook" ];
                          late = true;
                          rules = lib.concatMap (
                            sourceZone:
                            lib.forEach firezoneTargetZones (
                              targetZone:
                              lib.concatStringsSep " " [
                                "meta protocol { ip, ip6 }"
                                (lib.head nodeCfg.networking.nftables.firewall.zones.${sourceZone}.ingressExpression)
                                (lib.head nodeCfg.networking.nftables.firewall.zones.${targetZone}.egressExpression)
                                "masquerade random"
                              ]
                            )
                          ) [ "firezone" ];
                        };
                      };
                      firewall = {
                        rules = {
                          # forward firezone traffic
                          forward-incoming-firezone-traffic = {
                            from = [ "firezone" ];
                            to = firezoneTargetZones;
                            verdict = "accept";
                          };
                          # FIXME: is this needed? conntrack should take care of it and we want to masquerade anyway
                          forward-outgoing-firezone-traffic = {
                            from = firezoneTargetZones;
                            to = [ "firezone" ];
                            verdict = "accept";
                          };
                          # masquerade firezone traffic
                          masquerade-firezone = {
                            from = [ "firezone" ];
                            # masquerade = true; NOTE: custom rule below for ip4 + ip6
                            late = true; # Only accept after any rejects have been processed
                            to = firezoneTargetZones;
                            verdict = "accept";
                          };
                        };
                        zones.firezone.interfaces = [ "tun-firezone" ];
                      };
                    };
                  };
              }
              {
                ${idmServer} =
                  let
                    accountId = "7bc9f5a9-02b2-48f7-86f4-ff270b83c816";
                    externalId = "492fc5fe-8769-4c49-8a25-d02cda243d67";
                  in
                  confLib.mkKanidmOidcSystem {
                    inherit kanidmSopsFile serviceDomain serviceName;
                    displayName = "Firezone VPN";
                    # NOTE: state: both uuids are runtime values
                    originUrl = [
                      "https://${serviceDomain}/${accountId}/sign_in/providers/${externalId}/handle_callback"
                      "https://${serviceDomain}/${accountId}/settings/identity_providers/openid_connect/${externalId}/handle_callback"
                    ];
                  };
              }
              { ${webProxy}.services.nginx = genNginx serviceAddress ""; }
              { ${homeWebProxy}.services.nginx = lib.mkIf isHome (genNginx homeServiceAddress nginxAccessRules); }
            ]
          )
          {
            ${monitoringServer}.services.grafana.provision.alerting.rules.settings.groups = [
              {
                folder = "Infrastructure";
                interval = "1m";
                name = "firezone";
                orgId = 1;
                rules = [
                  (confLib.mkGrafanaAlertRule {
                    datasourceUid = "loki";
                    expr = ''sum(count_over_time({unit="firezone-server-api.service"} |= `not a valid match specification` [10m]))'';
                    forDuration = "5m";
                    noDataState = "OK";
                    op = "gt";
                    queryType = "instant";
                    summary = "firezone-server-api relay selection is crashing (ETS match-spec overflow from accumulated presence replicas); VPN gateway and client connections will fail. Restart all three firezone-server-* units to rebuild tracker state.";
                    threshold = 0;
                    title = "Firezone presence tracker match-spec overflow";
                    uid = "firezone_presence_match_spec_overflow";
                  })
                ];
              }
            ];
          }
        ];

      };
      disabledModules = map disabledFirezoneModule disabledFirezoneModules;
    }

  ;
}
