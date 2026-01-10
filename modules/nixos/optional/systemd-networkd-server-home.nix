{ self, lib, config, globals, ... }:
let
  inherit (globals.general) routerServer;
  inherit (config.swarselsystems) withMicroVMs isCrypted initrdVLAN;

  isRouter = config.node.name == routerServer;
  localVLANsList = config.swarselsystems.localVLANs;
  localVLANs = lib.genAttrs localVLANsList (x: globals.networks.home-lan.vlans.${x});
in
{
  imports = [
    "${self}/modules/nixos/optional/systemd-networkd-server.nix"
  ];
  config = {
    assertions = [
      {
        assertion = ((localVLANsList != [ ]) && (initrdVLAN != null)) || (localVLANsList == [ ]) || (!isCrypted);
        message = "This host uses VLANs and disk encryption, thus a VLAN must be specified for initrd or disk encryption must be removed.";
      }
    ];

    boot.initrd = lib.mkIf (isCrypted && (localVLANsList != [ ]) && (!isRouter)) {
      availableKernelModules = [ "8021q" ];
      kernelModules = [ "8021q" ]; # at least summers needs this to actually find the interfaces
      systemd.network = {
        enable = true;
        netdevs."30-vlan-${initrdVLAN}" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan-${initrdVLAN}";
          };
          vlanConfig.Id = globals.networks.home-lan.vlans.${initrdVLAN}.id;
        };
        networks = {
          "10-lan" = {
            matchConfig.Name = "lan";
            # This interface should only be used from attached vlans.
            # So don't acquire a link local address and only wait for
            # this interface to gain a carrier.
            networkConfig.LinkLocalAddressing = "no";
            linkConfig.RequiredForOnline = "carrier";
            vlan = [ "vlan-${initrdVLAN}" ];
          };
          "30-vlan-${initrdVLAN}" = {
            address = [
              globals.networks.home-lan.vlans.${initrdVLAN}.hosts.${config.node.name}.cidrv4
              globals.networks.home-lan.vlans.${initrdVLAN}.hosts.${config.node.name}.cidrv6
            ];
            matchConfig.Name = "vlan-${initrdVLAN}";
            networkConfig = {
              IPv6PrivacyExtensions = "yes";
            };
            linkConfig.RequiredForOnline = "routable";
          };
        };
      };
    };

    topology.self.interfaces = (lib.mapAttrs'
      (vlanName: _:
        lib.nameValuePair "vlan-${vlanName}" {
          network = lib.mkForce vlanName;
        }
      )
      localVLANs) // (lib.mapAttrs'
      (vlanName: _:
        lib.nameValuePair "me-${vlanName}" {
          network = lib.mkForce vlanName;
        }
      )
      localVLANs);

    systemd.network = {
      netdevs = lib.flip lib.concatMapAttrs localVLANs (
        vlanName: vlanCfg: {
          "30-vlan-${vlanName}" = {
            netdevConfig = {
              Kind = "vlan";
              Name = "vlan-${vlanName}";
            };
            vlanConfig.Id = vlanCfg.id;
          };
          # Create a MACVTAP for ourselves too, so that we can communicate with
          # our guests on the same interface.
          "40-me-${vlanName}" = lib.mkIf withMicroVMs {
            netdevConfig = {
              Name = "me-${vlanName}";
              Kind = "macvlan";
            };
            extraConfig = ''
              [MACVLAN]
              Mode=bridge
            '';
          };
        }
      );
      networks = {
        "10-lan" = lib.mkIf (!isRouter) {
          matchConfig.Name = "lan";
          # This interface should only be used from attached vlans.
          # So don't acquire a link local address and only wait for
          # this interface to gain a carrier.
          networkConfig.LinkLocalAddressing = "no";
          linkConfig.RequiredForOnline = "carrier";
          vlan = map (name: "vlan-${name}") (builtins.attrNames localVLANs);
        };
        # Remaining macvtap interfaces should not be touched.
        "90-macvtap-ignore" = lib.mkIf withMicroVMs {
          matchConfig.Kind = "macvtap";
          linkConfig.ActivationPolicy = "manual";
          linkConfig.Unmanaged = "yes";
        };
      }
      // lib.flip lib.concatMapAttrs localVLANs (
        vlanName: vlanCfg:
          let
            me = {
              address = [
                vlanCfg.hosts.${config.node.name}.cidrv4
                vlanCfg.hosts.${config.node.name}.cidrv6
              ];
              gateway = lib.optionals (vlanName == "services") [ vlanCfg.hosts.${routerServer}.ipv4 vlanCfg.hosts.${routerServer}.ipv6 ];
              matchConfig.Name = "${if withMicroVMs then "me" else "vlan"}-${vlanName}";
              networkConfig.IPv6PrivacyExtensions = "yes";
              linkConfig.RequiredForOnline = "routable";
            };

          in
          {
            "30-vlan-${vlanName}" = if (!withMicroVMs) then me else {
              matchConfig.Name = "vlan-${vlanName}";
              # This interface should only be used from attached macvlans.
              # So don't acquire a link local address and only wait for
              # this interface to gain a carrier.
              networkConfig.LinkLocalAddressing = "no";
              networkConfig.MACVLAN = "me-${vlanName}";
              linkConfig.RequiredForOnline = if isRouter then "no" else "carrier";
            };
            "40-me-${vlanName}" = lib.mkIf withMicroVMs (lib.mkDefault me);
          }
      );
    };

  };

}
