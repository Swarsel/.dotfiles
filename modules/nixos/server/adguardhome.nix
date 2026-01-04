{ self, inputs, lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "adguardhome"; port = 3000; }) serviceName servicePort serviceAddress serviceDomain proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied homeProxy homeProxyIf webProxy webProxyIf homeWebProxy dnsServer homeDnsServer homeServiceAddress nginxAccessRules;

  homeServices = lib.attrNames (lib.filterAttrs (_: serviceCfg: serviceCfg.isHome) globals.services);
  homeDomains = map (name: globals.services.${name}.domain) homeServices;
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {


    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome;
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };

    services.adguardhome = {
      enable = true;
      mutableSettings = false;
      host = "0.0.0.0";
      port = servicePort;
      settings = {
        dns = {
          bind_hosts = [
            globals.networks.home-lan.vlans.services.hosts.${homeDnsServer}.ipv4
            globals.networks.home-lan.vlans.services.hosts.${homeDnsServer}.ipv6
          ];
          ratelimit = 300;
          upstream_dns = [
            "https://dns.cloudflare.com/dns-query"
            "https://dns.google/dns-query"
            "https://doh.mullvad.net/dns-query"
          ];
          bootstrap_dns = [
            "1.1.1.1"
            "2606:4700:4700::1111"
            "8.8.8.8"
            "2001:4860:4860::8844"
          ];
          dhcp.enabled = false;
        };
        filtering.rewrites = [
        ]
        # Use the local mirror-proxy for some services (not necessary, just for speed)
        ++
        map
          (domain: {
            inherit domain;
            # FIXME: change to homeWebProxy once that is setup
            answer = globals.networks.home-lan.vlans.services.hosts.${homeWebProxy}.ipv4;
            # answer = globals.hosts.${webProxy}.wanAddress4;
          })
          homeDomains;
        filters = [
          {
            name = "AdGuard DNS filter";
            url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
            enabled = true;
          }
          {
            name = "AdAway Default Blocklist";
            url = "https://adaway.org/hosts.txt";
            enabled = true;
          }
          {
            name = "OISD (Big)";
            url = "https://big.oisd.nl";
            enabled = true;
          }
        ];
      };
    };

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      {
        directory = "/var/lib/private/AdGuardHome";
        mode = "0700";
      }
    ];

    nodes =
      let
        genNginx = toAddress: extraConfig: {
          upstreams = {
            ${serviceName} = {
              servers = {
                "${toAddress}:${builtins.toString servicePort}" = { };
              };
            };
          };
          virtualHosts = {
            "${serviceDomain}" = {
              useACMEHost = globals.domains.main;
              forceSSL = true;
              acmeRoot = null;
              oauth2 = {
                enable = true;
                allowedGroups = [ "adguardhome_access" ];
              };
              locations = {
                "/" = {
                  proxyPass = "http://${serviceName}";
                  proxyWebsockets = true;
                };
              };
              extraConfig = lib.mkIf (extraConfig != "") extraConfig;
            };
          };
        };
      in
      {
        ${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
          "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
        };
        ${webProxy}.services.nginx = genNginx serviceAddress "";
        ${homeWebProxy}.services.nginx = genNginx homeServiceAddress nginxAccessRules;
      };
  };
}
