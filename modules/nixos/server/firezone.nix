{ self, lib, pkgs, config, globals, confLib, dns, nodes, ... }:
let
  inherit (confLib.gen { name = "firezone"; dir = "/var/lib/private/firezone"; }) serviceName serviceDir serviceAddress serviceDomain proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied homeProxy webProxy homeWebProxy homeProxyIf webProxyIf idmServer dnsServer homeServiceAddress nginxAccessRules;
  inherit (config.swarselsystems) sopsFile;

  apiPort = 8081;
  webPort = 8080;
  relayPort = 3478;
  domainPort = 9003;

  homeServices = lib.attrNames (lib.filterAttrs (_: serviceCfg: serviceCfg.isHome) globals.services);
  homeDomains = map (name: globals.services.${name}.domain) homeServices;
  allow = group: resource: {
    "${group}@${resource}" = {
      inherit group resource;
      description = "Allow ${group} access to ${resource}";
    };
  };
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

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
        inherit proxyAddress4 proxyAddress6 isHome;
      };
    };

    topology.self.services.${serviceName} = {
      name = lib.swarselsystems.toCapitalized serviceName;
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

    sops = {
      secrets = {
        kanidm-firezone-client = { inherit sopsFile; mode = "0400"; };
        firezone-relay-token = { inherit sopsFile; mode = "0400"; };
        firezone-smtp-password = { inherit sopsFile; mode = "0440"; };
        firezone-adapter-config = { inherit sopsFile; mode = "0440"; };
      };
    };

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = serviceDir; mode = "0700"; }
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
                  clientSecretFile = config.sops.secrets.kanidm-firezone-client.path;
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
              // {
                "home.vlan-services.v4" = {
                  type = "cidr";
                  name = "home.vlan-services.v4";
                  address = globals.networks.home-lan.vlans.services.cidrv4;
                  gatewayGroups = [ "home" ];
                };
                "home.vlan-services.v6" = {
                  type = "cidr";
                  name = "home.vlan-services.v6";
                  address = globals.networks.home-lan.vlans.services.cidrv6;
                  gatewayGroups = [ "home" ];
                };
              };

            policies =
              { }
              // allow "everyone" "home.vlan-services.v4"
              // allow "anyone" "home.vlan-services.v4"
              // allow "everyone" "home.vlan-services.v6"
              // allow "anyone" "home.vlan-services.v6"
              // lib.mergeAttrsList (map (domain: allow "everyone" domain) homeDomains)
              // lib.mergeAttrsList (map (domain: allow "anyone" domain) homeDomains);
          };
        };

        domain = {
          settings.ERLANG_DISTRIBUTION_PORT = domainPort;
          package = pkgs.dev.firezone-server-domain;
        };
        api = {
          externalUrl = "https://${serviceDomain}/api/";
          address = "0.0.0.0";
          port = apiPort;
          package = pkgs.dev.firezone-server-api;
        };
        web = {
          externalUrl = "https://${serviceDomain}/";
          address = "0.0.0.0";
          port = webPort;
          package = pkgs.dev.firezone-server-web;
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
        package = pkgs.dev.firezone-relay;
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
                    to = [ "vlan-services" ];
                    # masquerade = true; NOTE: custom rule below for ip4 + ip6
                    late = true; # Only accept after any rejects have been processed
                    verdict = "accept";
                  };
                  # forward firezone traffic
                  forward-incoming-firezone-traffic = {
                    from = [ "firezone" ];
                    to = [ "vlan-services" ];
                    verdict = "accept";
                  };

                  # FIXME: is this needed? conntrack should take care of it and we want to masquerade anyway
                  forward-outgoing-firezone-traffic = {
                    from = [ "vlan-services" ];
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
                    lib.forEach
                      [
                        "firezone"
                      ]
                      (
                        zone:
                        lib.concatStringsSep " " [
                          "meta protocol { ip, ip6 }"
                          (lib.head nodeCfg.networking.nftables.firewall.zones.${zone}.ingressExpression)
                          (lib.head nodeCfg.networking.nftables.firewall.zones.vlan-services.egressExpression)
                          "masquerade random"
                        ]
                      );
                };
              };
            };

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
            nodeCfg = nodes.${idmServer}.config;
            accountId = "6b3c6ba7-5240-4684-95ce-f40fdae45096";
            externalId = "08d714e9-1ab9-4133-a39d-00e843a960cc";
          in
          {
            sops.secrets.kanidm-firezone = { inherit (nodeCfg.swarselsystems) sopsFile; owner = "kanidm"; group = "kanidm"; mode = "0440"; };
            services.kanidm.provision = {
              groups."firezone.access" = { };
              systems.oauth2.firezone = {
                displayName = "Firezone VPN";
                # NOTE: state: both uuids are runtime values
                originUrl = [
                  "https://${globals.services.firezone.domain}/${accountId}/sign_in/providers/${externalId}/handle_callback"
                  "https://${globals.services.firezone.domain}/${accountId}/settings/identity_providers/openid_connect/${externalId}/handle_callback"
                ];
                originLanding = "https://${globals.services.firezone.domain}/";
                basicSecretFile = nodeCfg.sops.secrets.kanidm-firezone.path;
                preferShortUsername = true;
                scopeMaps."firezone.access" = [
                  "openid"
                  "email"
                  "profile"
                ];
              };

            };
          };
        ${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
          "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
        };
        ${webProxy}.services.nginx = genNginx serviceAddress "";
        ${homeWebProxy}.services.nginx = lib.mkIf isHome (genNginx homeServiceAddress nginxAccessRules);
      };

  };
}
