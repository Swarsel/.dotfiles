{
  flake-file.inputs.nixpkgs-firezone.url = "github:Swarsel/nixpkgs/1fef1eb69b3f8f9a778441b386eadbb1fa3fa436?narHash=sha256-HY1UfmtZOuk7Y+9cTIF8Kx5TV7qOTtRqk7A+W6lyMm8%3D";

  flake.modules.nixos.firezone =
    {
      self,
      root,
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
        baseDomain
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
        serviceDomain
        serviceName
        subDomain
        ;
      inherit (confLib.static)
        homeProxy
        homeProxyIf
        homeServiceAddress
        homeWebProxy
        idmServer
        isHome
        isProxied
        nginxAccessRules
        notificationMail
        webProxy
        webProxyIf
        ;

      apiSubDomain = "${subDomain}-api";
      apiDomain = "${apiSubDomain}.${baseDomain}";

      portalPort = 8080;
      distributionPort = 9003;
      gatewayHealthPort = 8080;
      relayPort = 3478;
      relayHealthPort = 8082;

      firezoneTargetVLANs = [
        "services"
        "home"
        "devices"
        "iot"
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

      firezoneRpc = pkgs.writeShellApplication {
        name = "firezone-rpc";
        text = ''
          cd ${serviceDir}
          RELEASE_COOKIE=$(< secrets/RELEASE_COOKIE)
          export RELEASE_COOKIE
          export RELEASE_HOSTNAME=${config.services.firezone.server.settings.RELEASE_HOSTNAME}
          exec ${lib.getExe config.services.firezone.server.package} rpc "$@"
        '';
      };

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
      imports = [
        self.modules.nixos.postgresql
      ]
      ++ map (
        name: "${inputs.nixpkgs-firezone}/nixos/modules/${disabledFirezoneModule name}"
      ) disabledFirezoneModules;
      config = {
        swarselsystems = {
          enabledServerModules = [ "firezone" ];
          server.postgresql.rolePasswordFiles.firezone = config.sops.secrets.firezone-db-password.path;
        };
        topology.self.services.${serviceName} = {
          icon = root "files/topology-images/${serviceName}.png";
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
          dns = lib.mkMerge [
            (confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; })
            {
              ${baseDomain}.subdomainRecords.${apiSubDomain} =
                inputs.dns.lib.combinators.host proxyAddress4 proxyAddress6;
            }
          ];
          monitoring.http = lib.mkMerge [
            (confLib.mkHttpMonitoring {
              expectedBodyRegex = ''"status":"ready"'';
              path = "/readyz";
              serviceName = "firezone-server";
              servicePort = portalPort;
            })
            (confLib.mkHttpMonitoring {
              path = "/readyz";
              serviceName = "firezone-relay";
              servicePort = relayHealthPort;
            })
            {
              firezone-gateway = {
                network = "local-${homeProxy}";
                url = "http://127.0.0.1:${toString gatewayHealthPort}/healthz";
              };
            }
          ];
          networks = {
            ${homeProxyIf}.hosts = lib.mkIf isHome {
              ${config.node.name}.firewallRuleForNode.${homeWebProxy} = {
                allowedTCPPorts = [ portalPort ];
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
                allowedTCPPorts = [ portalPort ];
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
        sops.secrets = {
          firezone-db-password = {
            owner = config.systemd.services.postgresql.serviceConfig.User;
            rekey.generator.script = "alnum";
          };
          firezone-relay-token.mode = "0400";
          kanidm-firezone = {
            mode = "0400";
            rekey.keyPrefix = confLib.kanidmSecrets;
          };
          notification-mail-pw = {
            mode = "0440";
            rekey.keyPrefix = notificationMail.keyPrefix;
          };
        };
        services.firezone = {
          relay = {
            inherit (config.node) name;
            enable = true;
            apiUrl = "wss://${apiDomain}/";
            openFirewall = lib.mkIf (!isProxied) true;
            port = relayPort;
            publicIpv4 = proxyAddress4;
            publicIpv6 = proxyAddress6;
            tokenFile = config.sops.secrets.firezone-relay-token.path;
          };
          server = {
            enable = true;
            api.externalUrl = "https://${apiDomain}/";
            enableLocalDB = true;
            portal = {
              address = "0.0.0.0";
              port = portalPort;
            };
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
                    issuer = "https://${globals.services.kanidm.domain}/oauth2/openid/${client_id}";
                  in
                  {
                    adapter = "oidc";
                    adapter_config = {
                      inherit client_id issuer;
                      client_secret._secret = config.sops.secrets.kanidm-firezone.path;
                      discovery_document_uri = "${issuer}/.well-known/openid-configuration";
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
            settings.ERLANG_DISTRIBUTION_PORT = distributionPort;
            settingsSecret.DATABASE_PASSWORD = config.sops.secrets.firezone-db-password.path;
            smtp = {
              inherit (config.repo.secrets.local.firezone.mail) from username;
              inherit (notificationMail) host;
              implicitTls = true;
              passwordFile = config.sops.secrets.notification-mail-pw.path;
              port = 465;
            };
            web.externalUrl = "https://${serviceDomain}/";
          };
        };
        environment = {
          persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
            {
              directory = serviceDir;
              mode = "0700";
            }
            {
              directory = "${serviceDir}-relay";
              mode = "0700";
            }
          ];
          systemPackages = [ firezoneRpc ];
        };
        systemd.services = {
          firezone-relay.environment.HEALTH_CHECK_ADDR = "0.0.0.0:${toString relayHealthPort}";
          firezone-server = {
            serviceConfig.RestartSec = lib.mkForce 30;
            startLimitBurst = 10;
            startLimitIntervalSec = 600;
          };
        };
        nodes =
          let
            genNginx = toAddress: extraConfig: {
              upstreams.${serviceName}.servers."${toAddress}:${toString portalPort}" = { };
              virtualHosts = lib.genAttrs [ serviceDomain apiDomain ] (_: {
                inherit extraConfig;
                acmeRoot = null;
                forceSSL = true;
                locations."/" = {
                  proxyPass = "http://${serviceName}/";
                  proxyWebsockets = true;
                };
                useACMEHost = globals.domains.main;
              });
            };
          in
          lib.mkMerge [
            {
              ${homeProxy} =
                let
                  nodeCfg = nodes.${homeProxy}.config;
                in
                {
                  topology.self.services."${serviceName}-gateway" = {
                    icon = root "files/topology-images/${serviceName}.png";
                    name = lib.swarselsystems.toCapitalized "${serviceName} Gateway";
                  };
                  sops.secrets.firezone-gateway-token.mode = "0400";
                  services.firezone.gateway = {
                    inherit (nodeCfg.node) name;
                    enable = true;
                    apiUrl = "wss://${apiDomain}/";
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
                    chains.postrouting.masquerade-firezone = {
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
                    firewall = {
                      rules = {
                        forward-incoming-firezone-traffic = {
                          from = [ "firezone" ];
                          to = firezoneTargetZones;
                          verdict = "accept";
                        };
                        forward-outgoing-firezone-traffic = {
                          from = firezoneTargetZones;
                          to = [ "firezone" ];
                          verdict = "accept";
                        };
                        masquerade-firezone = {
                          from = [ "firezone" ];
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
                  accountId = "33464cc5-ccc5-4565-b842-1cc323c2df5f";
                  externalId = "2322e386-689f-4035-a64b-ce932c2d3c61";
                in
                confLib.mkKanidmOidcSystem {
                  inherit serviceDomain serviceName;
                  displayName = "Firezone VPN";
                  originUrl = [
                    "https://${serviceDomain}/auth/oidc/callback"
                    "https://${serviceDomain}/${accountId}/sign_in/providers/${externalId}/handle_callback"
                    "https://${serviceDomain}/${accountId}/settings/identity_providers/openid_connect/${externalId}/handle_callback"
                  ];
                };
            }
            { ${webProxy}.services.nginx = genNginx serviceAddress ""; }
            { ${homeWebProxy}.services.nginx = lib.mkIf isHome (genNginx homeServiceAddress nginxAccessRules); }
          ];

      };
      disabledModules = map disabledFirezoneModule disabledFirezoneModules;
    }

  ;
}
