{
  flake.modules.nixos.croc =
    {
      self,
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "croc";
          proxy = config.node.name;
        })
        proxyAddress4
        proxyAddress6
        serviceDomain
        serviceName
        ;
      inherit (confLib.static) isHome;
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
      config = {
        swarselsystems.enabledServerModules = [ "croc" ];
        topology.self.services.${serviceName} = {
          icon = "${self}/files/topology-images/${serviceName}.png";
          info = "https://${serviceDomain}";
          name = serviceName;
        };
        globals = {
          services.${serviceName} = {
            inherit isHome proxyAddress4 proxyAddress6;
            domain = serviceDomain;
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
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
        services.${serviceName} = {
          enable = true;
          openFirewall = true;
          pass = config.sops.secrets.croc-password.path;
          ports = servicePorts;
        };
        systemd.services = {
          ${serviceName} = {
            serviceConfig = {
              EnvironmentFile = [
                config.sops.templates.croc-env.path
              ];
              ExecStart = lib.mkForce "${pkgs.croc}/bin/croc ${lib.optionalString cfg.debug "--debug"} relay --ports ${
                lib.concatMapStringsSep "," toString cfg.ports
              }";
            };
          };
        };
        # ports are opened on the firewall for croc, no nginx config

      };

    }

  ;
}
