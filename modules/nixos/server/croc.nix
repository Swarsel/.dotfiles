{ self, lib, config, pkgs, ... }:
let
  servicePorts = [
    9009
    9010
    9011
    9012
    9013
  ];
  serviceName = "croc";
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};

  inherit (config.swarselsystems) sopsFile;

  cfg = config.services.croc;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

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

    globals.services.${serviceName}.domain = serviceDomain;

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
