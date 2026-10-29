{
  flake.modules.nixos.chrony =
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
          dir = "/var/lib/chrony";
          name = "chrony";
          port = 123;
        })
        serviceDir
        serviceGroup
        serviceName
        servicePort
        serviceUser
        ;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName}.name = lib.swarselsystems.toCapitalized serviceName;
        globals.monitoring.systemd = confLib.mkSystemdMonitoring {
          inherit serviceName;
          unit = "chronyd.service";
        };
        services.${serviceName} = {
          enable = true;
          extraConfig = lib.concatMapStrings (vlan: ''
            allow ${vlan.cidrv4}
            allow ${vlan.cidrv6}
          '') (builtins.attrValues globals.networks.home-lan.vlans);
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            group = serviceGroup;
            mode = "0750";
            user = serviceUser;
          }
        ];
        networking.nftables.firewall.rules.ntp-to-local = {
          allowedUDPPorts = [ servicePort ];
          from = map (name: "vlan-${name}") (builtins.attrNames globals.networks.home-lan.vlans);
          to = [ "local" ];
        };
      };
    }

  ;
}
