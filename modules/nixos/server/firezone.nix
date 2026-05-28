{ self, lib, pkgs, config, globals, confLib, nodes, ... }:
let
  inherit (confLib.gen { name = "firezone"; dir = "/var/lib/private/firezone"; }) serviceName serviceDir serviceAddress serviceDomain proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied homeProxy webProxy homeWebProxy homeProxyIf webProxyIf idmServer homeServiceAddress nginxAccessRules;
  inherit (config.swarselsystems) sopsFile;

  apiPort = 8081;
  webPort = 8080;
  relayPort = 3478;
  domainPort = 9003;

  firezoneTargetVLANs = [ "services" "home" "devices" ];
  firezoneTargetZones = map (v: "vlan-${v}") firezoneTargetVLANs;

  homeServices = lib.attrNames (lib.filterAttrs (_: serviceCfg: serviceCfg.isHome) globals.services);
  homeDomains = map (name: globals.services.${name}.domain) homeServices;
  vlanCidrResources = lib.listToAttrs (lib.concatMap
    (vlan: [
      {
        name = "home.vlan-${vlan}.v4";
        value = {
          type = "cidr";
          name = "home.vlan-${vlan}.v4";
          address = globals.networks.home-lan.vlans.${vlan}.cidrv4;
          gatewayGroups = [ "home" ];
        };
      }
      {
        name = "home.vlan-${vlan}.v6";
        value = {
          type = "cidr";
          name = "home.vlan-${vlan}.v6";
          address = globals.networks.home-lan.vlans.${vlan}.cidrv6;
          gatewayGroups = [ "home" ];
        };
      }
    ])
    firezoneTargetVLANs);
  allow = group: resource: {
    "${group}@${resource}" = {
      inherit group resource;
      description = "Allow ${group} access to ${resource}";
    };
  };

  kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
in
{
  config = {
    swarselsystems.enabledServerModules = [ "firezone" ];

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy} = {
            allowedTCPPorts = [ apiPort webPort domainPort ];
            allowedUDPPorts = [ relayPort ];
            allowedUDPPortRanges = [
              {
                from = config.services.firezone.relay.lowestPort;
                to = config.services.firezone.relay.highestPort;
              }
            ];
          };
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeWebProxy} = {
            allowedTCPPorts = [ apiPort webPort domainPort ];
            allowedUDPPorts = [ relayPort ];
            allowedUDPPortRanges = [
              {
                from = config.services.firezone.relay.lowestPort;
                to = config.services.firezone.relay.highestPort;
              }
            ];
          };
        };
      };
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome serviceAddress;
        homeServiceAddress = lib.mkIf isHome homeServiceAddress;
      };
    };

    topology.self.services.${serviceName} = {
      name = lib.swarselsystems.toCapitalized serviceName;
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

    sops = {
      secrets = {
        kanidm-firezone = { sopsFile = kanidmSopsFile; mode = "0400"; };
        firezone-relay-token = { inherit sopsFile; mode = "0400"; };
        firezone-smtp-password = { inherit sopsFile; mode = "0440"; };
        firezone-adapter-config = { inherit sopsFile; mode = "0440"; };
      };
    };

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = serviceDir; mode = "0700"; }
      { directory = "${serviceDir}-relay"; mode = "0700"; }
    ];

    services.firezone = {
      server = {
        enable = true;
        enableLocalDB = true;

        smtp = {
          inherit (config.repo.secrets.local.firezone.mail) from username;
          host = globals.services.mailserver.domain;
          port = 465;
          implicitTls = true;
          passwordFile = config.sops.secrets.firezone-smtp-password.path;
        };

        provision = {
          enable = true;
          accounts.main = {
            name = "Home";
            relayGroups.relays.name = "Relays";
            gatewayGroups.home.name = "Home";
            actors.admin = {
              type = "account_admin_user";
              name = "Admin";
              email = "admin@${globals.domains.main}";
            };
            groups.anyone = {
              name = "anyone";
              members = [
                "admin"
              ];
            };

            auth.oidc =
              let
                client_id = "firezone";
              in
              {
                name = "Kanidm";
                adapter = "openid_connect";
                adapter_config = {
                  scope = "openid email profile";
                  response_type = "code";
                  inherit client_id;
                  discovery_document_uri = "https://${globals.services.kanidm.domain}/oauth2/openid/${client_id}/.well-known/openid-configuration";
                  clientSecretFile = config.sops.secrets.kanidm-firezone.path;
                };
              };

            resources =
              lib.genAttrs homeDomains
                (domain: {
                  type = "dns";
                  name = domain;
                  address = domain;
                  gatewayGroups = [ "home" ];
                  filters = [
                    { protocol = "icmp"; }
                    {
                      protocol = "tcp";
                      ports = [
                        443
                        80
                      ];
                    }
                    {
                      protocol = "udp";
                      ports = [ 443 ];
                    }
                  ];
                })
              // vlanCidrResources;

            policies =
              { }
              // lib.mergeAttrsList (lib.concatMap
                (resource: [
                  (allow "everyone" resource)
                  (allow "anyone" resource)
                ])
                (lib.attrNames vlanCidrResources))
              // lib.mergeAttrsList (map (domain: allow "everyone" domain) homeDomains)
              // lib.mergeAttrsList (map (domain: allow "anyone" domain) homeDomains);
          };
        };

        domain = {
          settings.ERLANG_DISTRIBUTION_PORT = domainPort;
          package = pkgs.firezone-server-domain;
        };
        api = {
          externalUrl = "https://${serviceDomain}/api/";
          address = "0.0.0.0";
          port = apiPort;
          package = pkgs.firezone-server-api;
        };
        web = {
          externalUrl = "https://${serviceDomain}/";
          address = "0.0.0.0";
          port = webPort;
          package = pkgs.firezone-server-web;
        };
      };

      relay = {
        enable = true;
        port = relayPort;
        inherit (config.node) name;
        apiUrl = "wss://${serviceDomain}/api/";
        tokenFile = config.sops.secrets.firezone-relay-token.path;
        publicIpv4 = proxyAddress4;
        publicIpv6 = proxyAddress6;
        openFirewall = lib.mkIf (!isProxied) true;
        package = pkgs.firezone-relay;
      };
    };
    # systemd.services.firezone-initialize =
    #   let
    #     generateSecrets =
    #       let
    #         requiredSecrets = lib.filterAttrs (_: v: v == null) cfg.settingsSecret;
    #       in
    #       ''
    #         mkdir -p secrets
    #         chmod 700 secrets
    #       ''
    #       + lib.concatLines (
    #         lib.forEach (builtins.attrNames requiredSecrets) (secret: ''
    #           if [[ ! -e secrets/${secret} ]]; then
    #             echo "Generating ${secret}"
    #             # Some secrets like TOKENS_KEY_BASE require a value >=64 bytes.
    #             head -c 64 /dev/urandom | base64 -w 0 > secrets/${secret}
    #             chmod 600 secrets/${secret}
    #           fi
    #         '')
    #       );
    #     loadSecretEnvironment =
    #       component:
    #       let
    #         relevantSecrets = lib.subtractLists (builtins.attrNames cfg.${component}.settings) (
    #           builtins.attrNames cfg.settingsSecret
    #         );
    #       in
    #       lib.concatLines (
    #         lib.forEach relevantSecrets (
    #           secret:
    #           ''export ${secret}=$(< ${
    #                       if cfg.settingsSecret.${secret} == null then
    #                         "secrets/${secret}"
    #                       else
    #                         "\"$CREDENTIALS_DIRECTORY/${secret}\""
    #                     })''
    #         )
    #       );
    #   in
    #   {
    #     script = lib.mkForce ''
    #       mkdir -p "$TZDATA_DIR"

    #       # Generate and load secrets
    #       ${generateSecrets}
    #       ${loadSecretEnvironment "domain"}

    #       echo "Running migrations"
    #       ${lib.getExe cfg.domain.package} eval "Domain.Release.migrate(manual: true)"
    #     '';
    #   };



    globals.dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };

    nodes =
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
              useACMEHost = globals.domains.main;
              forceSSL = true;
              acmeRoot = null;
              inherit extraConfig;
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
            };
          };
        };
      in
      {
        ${homeProxy} =
          let
            nodeCfg = nodes.${homeProxy}.config;
            nodePkgs = nodes.${homeProxy}.pkgs;
          in
          {
            sops.secrets.firezone-gateway-token = { inherit (nodeCfg.swarselsystems) sopsFile; mode = "0400"; };
            networking.nftables = {
              firewall = {
                zones.firezone.interfaces = [ "tun-firezone" ];
                rules = {
                  # masquerade firezone traffic
                  masquerade-firezone = {
                    from = [ "firezone" ];
                    to = firezoneTargetZones;
                    # masquerade = true; NOTE: custom rule below for ip4 + ip6
                    late = true; # Only accept after any rejects have been processed
                    verdict = "accept";
                  };
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
                };
              };
              chains.postrouting = {
                masquerade-firezone = {
                  after = [ "hook" ];
                  late = true;
                  rules =
                    lib.concatMap
                      (sourceZone:
                        lib.forEach firezoneTargetZones (
                          targetZone:
                          lib.concatStringsSep " " [
                            "meta protocol { ip, ip6 }"
                            (lib.head nodeCfg.networking.nftables.firewall.zones.${sourceZone}.ingressExpression)
                            (lib.head nodeCfg.networking.nftables.firewall.zones.${targetZone}.egressExpression)
                            "masquerade random"
                          ]
                        ))
                      [ "firezone" ];
                };
              };
            };

            environment.persistence."/persist".directories = lib.mkIf nodeCfg.swarselsystems.isImpermanence [
              { directory = "${serviceDir}-gateway"; mode = "0700"; }
            ];

            boot.kernel.sysctl = {
              "net.core.wmem_max" = 16777216;
              "net.core.rmem_max" = 134217728;
            };
            services.firezone.gateway = {
              enable = true;
              # logLevel = "trace";
              inherit (nodeCfg.node) name;
              apiUrl = "wss://${globals.services.firezone.domain}/api/";
              tokenFile = nodeCfg.sops.secrets.firezone-gateway-token.path;
              package = nodePkgs.stable25_05.firezone-gateway; # newer versions of firezone-gateway are not compatible with server package
            };

            topology.self.services."${serviceName}-gateway" = {
              name = lib.swarselsystems.toCapitalized "${serviceName} Gateway";
              icon = "${self}/files/topology-images/${serviceName}.png";
            };
          };
        ${idmServer} =
          let
            accountId = "7bc9f5a9-02b2-48f7-86f4-ff270b83c816";
            externalId = "492fc5fe-8769-4c49-8a25-d02cda243d67";
          in
          confLib.mkKanidmOidcSystem {
            inherit serviceName serviceDomain kanidmSopsFile;
            displayName = "Firezone VPN";
            # NOTE: state: both uuids are runtime values
            originUrl = [
              "https://${serviceDomain}/${accountId}/sign_in/providers/${externalId}/handle_callback"
              "https://${serviceDomain}/${accountId}/settings/identity_providers/openid_connect/${externalId}/handle_callback"
            ];
          };
        ${webProxy}.services.nginx = genNginx serviceAddress "";
        ${homeWebProxy}.services.nginx = lib.mkIf isHome (genNginx homeServiceAddress nginxAccessRules);
      };

  };
}
