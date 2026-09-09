{
  flake.modules.nixos.acme-dns =
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
          dir = "/var/lib/private/acme-dns";
          domain = "";
          name = "acme-dns";
          port = 8053;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
        serviceDomain
        serviceName
        servicePort
        ;
      inherit (confLib.static) homeServiceAddress isHome;
      inherit (config.swarselsystems.server) localNetwork netConfigName;
      inherit (globals.domains) reverse6;

      zoneLabel = "dns";
      zone = "${zoneLabel}.${reverse6}";
      addressId = 53;
      listenAddress6 = lib.net.cidr.host addressId globals.networks.${netConfigName}.cidrv6;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          info = zone;
          name = serviceName;
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
            extra.extraConfig.port = servicePort;
          };
          dns.${reverse6}.subdomainRecords.${zoneLabel} = {
            AAAA = [ listenAddress6 ];
            NS = [ "${zone}." ];
          };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            path = "/health";
          };
        };
        services.acme-dns = {
          enable = true;
          settings = {
            api = {
              disable_registration = true;
              header_name = "X-Forwarded-For";
              port = servicePort;
              tls = "none";
              use_header = true;
            };
            general = {
              domain = zone;
              listen = "[${listenAddress6}]:53";
              nsadmin = lib.replaceStrings [ "@" ] [ "." ] config.repo.secrets.common.dnsMail;
              nsname = zone;
              protocol = "both6";
              records = [
                "${zone}. AAAA ${listenAddress6}"
                "${zone}. NS ${zone}."
              ];
            };
            logconfig = {
              logformat = "text";
              loglevel = "info";
              logtype = "stdout";
            };
          };
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            mode = "0700";
          }
        ];
        systemd = {
          services.acme-dns.serviceConfig.RestartSec = 5;
          network.networks."10-${localNetwork}".address = [
            (lib.net.cidr.hostCidr addressId globals.networks.${netConfigName}.cidrv6)
          ];
        };
      };
    };
}
