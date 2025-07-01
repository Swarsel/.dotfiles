{ self, lib, config, pkgs, ... }:
let
  serviceDomain = "send.swarsel.win";
  servicePorts = [
    9009
    9010
    9011
    9012
    9013
  ];
  serviceName = "croc";

  cfg = config.services.croc;
in
{
  options.swarselsystems.modules.server."${serviceName}" = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server."${serviceName}" {

    sops = {
      secrets = {
        croc-password = { };
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
      icon = "${self}/topology/images/${serviceName}.png";
    };

    globals.services.${serviceName}.domain = serviceDomain;

    services.croc = {
      enable = true;
      ports = servicePorts;
      pass = config.sops.secrets.croc-password.path;
      openFirewall = true;
    };


    systemd.services = {
      "${serviceName}" = {
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
