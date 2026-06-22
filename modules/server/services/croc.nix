{
  flake.modules.nixos.croc =
    {
      self,
      lib,
      config,
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
        serviceName
        serviceDomain
        proxyAddress4
        proxyAddress6
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
          name = serviceName;
          info = "https://${serviceDomain}";
          icon = "${self}/files/topology-images/${serviceName}.png";
        };

        globals = {
          dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
          services.${serviceName} = {
            domain = serviceDomain;
            inherit proxyAddress4 proxyAddress6 isHome;
          };
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
                lib.concatMapStringsSep "," toString cfg.ports
              }";
              EnvironmentFile = [
                config.sops.templates.croc-env.path
              ];
            };
          };
        };

        # ports are opened on the firewall for croc, no nginx config

      };

    }

  ;
}
