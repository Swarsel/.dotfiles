{ self, lib, config, pkgs, dns, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "croc"; }) serviceName serviceDomain proxyAddress4 proxyAddress6;
  servicePorts = [
    9009
    9010
    9011
    9012
    9013
  ];

  inherit (config.swarselsystems) sopsFile;

  cfg = config.services.croc;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    nodes.stoicclub.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    sops = {
      secrets = {
        croc-password = { inherit sopsFile; };
      };

      templates = {
        "croc-env" = {
          content = ''
            CROC_PASS="${config.sops.placeholder.croc-password}"
          '';
        };
      };
    };


    topology.self.services.${serviceName} = {
      name = lib.swarselsystems.toCapitalized serviceName;
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
    };

    services.${serviceName} = {
      enable = true;
      ports = servicePorts;
      pass = config.sops.secrets.croc-password.path;
      openFirewall = true;
    };


    systemd.services = {
      ${serviceName} = {
        serviceConfig = {
          ExecStart = lib.mkForce "${pkgs.croc}/bin/croc ${lib.optionalString cfg.debug "--debug"} relay --ports ${
            lib.concatMapStringsSep "," toString cfg.ports}";
          EnvironmentFile = [
            config.sops.templates.croc-env.path
          ];
        };
      };
    };

    # ports are opened on the firewall for croc, no nginx config

  };

}
