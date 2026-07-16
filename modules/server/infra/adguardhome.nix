{
  flake.modules.nixos.adguardhome =
    {
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "adguardhome";
          port = 3000;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceName
        servicePort
        ;
      inherit (confLib.static)
        homeDnsServer
        homeServiceAddress
        homeWebProxy
        idmServer
        isHome
        nginxAccessRules
        webProxy
        ;

      homeServices = lib.attrNames (lib.filterAttrs (_: serviceCfg: serviceCfg.isHome) globals.services);
      homeDomains = map (name: globals.services.${name}.domain) homeServices;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "adguardhome" ];
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
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = ''"running":true'';
            path = "/control/status";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        services.adguardhome = {
          enable = true;
          host = "0.0.0.0";
          mutableSettings = false;
          port = servicePort;
          settings = {
            dns = {
              bind_hosts = [
                globals.networks.home-lan.vlans.services.hosts.${homeDnsServer}.ipv4
                globals.networks.home-lan.vlans.services.hosts.${homeDnsServer}.ipv6
              ];
              bootstrap_dns = [
                "1.1.1.1"
                "2606:4700:4700::1111"
                "8.8.8.8"
                "2001:4860:4860::8844"
              ];
              dhcp.enabled = false;
              ratelimit = 300;
              upstream_dns = [
                "https://dns.cloudflare.com/dns-query"
                "https://dns.google/dns-query"
                "https://doh.mullvad.net/dns-query"
              ];
            };
            filtering.rewrites =
              (map (domain: {
                inherit domain;
                # FIXME: change to homeWebProxy once that is setup
                answer = globals.networks.home-lan.vlans.services.hosts.${homeWebProxy}.ipv4;
                # answer = globals.hosts.${webProxy}.wanAddress4;
                enabled = true;
              }) homeDomains)
              ++ [
                {
                  answer = globals.networks.home-lan.vlans.services.hosts.summers-storage.ipv4;
                  domain = "smb.${globals.domains.main}";
                  enabled = true;
                }
              ];
            filters = [
              {
                enabled = true;
                name = "AdGuard DNS filter";
                url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
              }
              {
                enabled = true;
                name = "AdAway Default Blocklist";
                url = "https://adaway.org/hosts.txt";
              }
              {
                enabled = true;
                name = "OISD (Big)";
                url = "https://big.oisd.nl";
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
        networking.firewall = {
          allowedTCPPorts = [ 53 ];
          allowedUDPPorts = [ 53 ];
        };
        nodes = lib.mkMerge [
          {
            ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; };
          }
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              oauth2 = true;
              oauth2Groups = [ "adguardhome_access" ];
              proxyWebsockets = true;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                oauth2 = true;
                oauth2Groups = [ "adguardhome_access" ];
                proxyWebsockets = true;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];
      };
    }

  ;
}
