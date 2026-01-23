{ lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "adguardhome"; port = 3000; }) serviceName servicePort serviceAddress serviceDomain proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied homeProxyIf webProxy webProxyIf homeWebProxy dnsServer homeDnsServer homeServiceAddress nginxAccessRules;

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
          ${config.node.name}.firewallRuleForNode.${homeWebProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome serviceAddress;
        homeServiceAddress = lib.mkIf isHome homeServiceAddress;
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
        filtering.rewrites = (map
          (domain: {
            inherit domain;
            # FIXME: change to homeWebProxy once that is setup
            answer = globals.networks.home-lan.vlans.services.hosts.${homeWebProxy}.ipv4;
            # answer = globals.hosts.${webProxy}.wanAddress4;
            enabled = true;
          })
          homeDomains) ++ [
          {
            domain = "smb.${globals.domains.main}";
            answer = globals.networks.home-lan.vlans.services.hosts.storage.ipv4;
            enabled = true;
          }
        ];
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
        user_rules = config.repo.secrets.local.adguardUserRules;
      };
    };

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      {
        directory = "/var/lib/private/AdGuardHome";
        mode = "0700";
      }
    ];

    nodes = {
      ${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
        "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
      };
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; proxyWebsockets = true; oauth2 = true; oauth2Groups = [ "adguardhome_access" ]; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; proxyWebsockets = true; oauth2 = true; oauth2Groups = [ "adguardhome_access" ]; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };
  };
}
