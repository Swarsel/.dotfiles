{
  flake.modules.nixos.kea =
    {
      self,
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/private/kea";
          name = "kea";
        })
        serviceDir
        serviceName
        ;
      inherit (confLib.static) homeDnsServer;
      dhcpX =
        intX:
        let
          x = builtins.toString intX;
        in
        {
          enable = true;
          settings = {
            interfaces-config = {
              interfaces = map (name: "me-${name}") (builtins.attrNames globals.networks.home-lan.vlans);
              service-sockets-max-retries = -1;
            };
            lease-database = {
              name = "/var/lib/kea/dhcp${x}.leases";
              persist = true;
              type = "memfile";
            };
            renew-timer = 3600;
            reservations-out-of-pool = true;
            "subnet${x}" = lib.flip lib.mapAttrsToList globals.networks.home-lan.vlans (
              vlanName: vlanCfg: {
                inherit (vlanCfg) id;
                interface = "me-${vlanName}";
                option-data =
                  lib.optional (intX == 4) {
                    data = vlanCfg.hosts.hintbooth."ipv${x}";
                    name = "routers";
                  }
                  # Advertise DNS server for VLANS that have internet access
                  ++ lib.optional (lib.elem vlanName globals.general.internetVLANs) {
                    data = globals.networks.home-lan.vlans.services.hosts.${homeDnsServer}."ipv${x}";
                    name = if (intX == 4) then "domain-name-servers" else "dns-servers";
                  }
                  ++ lib.optional (lib.elem vlanName globals.general.internetVLANs) {
                    data = globals.domains.main;
                    name = "domain-search";
                  };
                pd-pools = lib.mkIf (intX == 6) [
                  {
                    delegated-len = 64;
                    prefix = builtins.replaceStrings [ "::" ] [ ":0:0:100::" ] (
                      lib.head (lib.splitString "/" vlanCfg.cidrv6)
                    );
                    prefix-len = 56;
                  }
                ];
                pools = [
                  {
                    pool = "${lib.net.cidr.host 100 vlanCfg."cidrv${x}"} - ${
                      lib.net.cidr.host (-6) vlanCfg."cidrv${x}"
                    }";
                  }
                ];
                rapid-commit = lib.mkIf (intX == 6) true;
                reservations = lib.concatLists (
                  lib.forEach (builtins.attrValues vlanCfg.hosts) (
                    hostCfg:
                    lib.optional (hostCfg.mac != null) {
                      duid = lib.mkIf (intX == 6) "00:03:00:01:${hostCfg.mac}"; # 00:03 = duid type 3; 00:01 = ethernet
                      hw-address = lib.mkIf (intX == 4) hostCfg.mac;
                      ip-address = lib.mkIf (intX == 4) hostCfg."ipv${x}";
                      ip-addresses = lib.mkIf (intX == 6) [ hostCfg."ipv${x}" ];
                      prefixes = lib.mkIf (intX == 6) [
                        "${
                          builtins.replaceStrings [ "::" ] [ ":0:0:${builtins.toString (256 + hostCfg.id)}::" ] (
                            lib.head (lib.splitString "/" vlanCfg.cidrv6)
                          )
                        }/64"
                      ];
                    }
                  )
                );
                subnet = vlanCfg."cidrv${x}";
              }
            );
            valid-lifetime = 86400;
          };
        };
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "kea" ];
        topology = {
          extractors.kea.enable = false;
          self.services.${serviceName} = {
            icon = "${self}/files/topology-images/${serviceName}.png";
            name = lib.swarselsystems.toCapitalized serviceName;
          };
        };
        users.persistentIds.kea = confLib.mkIds 968;
        services.kea = {
          dhcp4 = dhcpX 4;
          dhcp6 = dhcpX 6;
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            mode = "0700";
          }
        ];

      };
    }

  ;
}
