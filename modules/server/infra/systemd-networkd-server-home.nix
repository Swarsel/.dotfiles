{
  flake.modules.nixos.systemd-networkd-server-home =
    {
      self,
      config,
      lib,
      globals,
      ...
    }:
    let
      inherit (globals.general) routerServer;
      inherit (config.swarselsystems) initrdVLAN isCrypted withMicroVMs;

      isRouter = config.node.name == routerServer;
      localVLANsList = config.swarselsystems.localVLANs;
      localVLANs = lib.genAttrs localVLANsList (x: globals.networks.home-lan.vlans.${x});
    in
    {
      imports = [
        self.modules.nixos.systemd-networkd-server
      ];
      config = {
        topology.self.interfaces =
          (lib.mapAttrs' (
            vlanName: _:
            lib.nameValuePair "vlan-${vlanName}" {
              network = lib.mkForce vlanName;
            }
          ) localVLANs)
          // (lib.mapAttrs' (
            vlanName: _:
            lib.nameValuePair "me-${vlanName}" {
              network = lib.mkForce vlanName;
            }
          ) localVLANs);
        assertions = [
          {
            assertion =
              ((localVLANsList != [ ]) && (initrdVLAN != null)) || (localVLANsList == [ ]) || (!isCrypted);
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
                linkConfig.RequiredForOnline = "carrier";
                matchConfig.Name = "lan";
                # This interface should only be used from attached vlans.
                # So don't acquire a link local address and only wait for
                # this interface to gain a carrier.
                networkConfig.LinkLocalAddressing = "no";
                vlan = [ "vlan-${initrdVLAN}" ];
              };
              "30-vlan-${initrdVLAN}" = {
                address = [
                  globals.networks.home-lan.vlans.${initrdVLAN}.hosts.${config.node.name}.cidrv4
                  globals.networks.home-lan.vlans.${initrdVLAN}.hosts.${config.node.name}.cidrv6
                ];
                linkConfig.RequiredForOnline = "routable";
                matchConfig.Name = "vlan-${initrdVLAN}";
                networkConfig = {
                  IPv6PrivacyExtensions = "yes";
                };
              };
            };
          };
        };
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
                extraConfig = ''
                  [MACVLAN]
                  Mode=bridge
                '';
                netdevConfig = {
                  Kind = "macvlan";
                  Name = "me-${vlanName}";
                };
              };
            }
          );
          networks = {
            "10-lan" = lib.mkIf (!isRouter) {
              linkConfig.RequiredForOnline = "carrier";
              matchConfig.Name = "lan";
              # This interface should only be used from attached vlans.
              # So don't acquire a link local address and only wait for
              # this interface to gain a carrier.
              networkConfig.LinkLocalAddressing = "no";
              vlan = map (name: "vlan-${name}") (builtins.attrNames localVLANs);
            };
            # Remaining macvtap interfaces should not be touched.
            "90-macvtap-ignore" = lib.mkIf withMicroVMs {
              linkConfig = {
                ActivationPolicy = "manual";
                Unmanaged = "yes";
              };
              matchConfig.Kind = "macvtap";
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
                gateway = lib.optionals (vlanName == "services") [
                  vlanCfg.hosts.${routerServer}.ipv4
                  vlanCfg.hosts.${routerServer}.ipv6
                ];
                linkConfig.RequiredForOnline = "routable";
                matchConfig.Name = "${if withMicroVMs then "me" else "vlan"}-${vlanName}";
                networkConfig.IPv6PrivacyExtensions = "yes";
              };

            in
            {
              "30-vlan-${vlanName}" =
                if (!withMicroVMs) then
                  me
                else
                  {
                    linkConfig.RequiredForOnline = if isRouter then "no" else "carrier";
                    matchConfig.Name = "vlan-${vlanName}";
                    networkConfig = {
                      # This interface should only be used from attached macvlans.
                      # So don't acquire a link local address and only wait for
                      # this interface to gain a carrier.
                      LinkLocalAddressing = "no";
                      MACVLAN = "me-${vlanName}";
                    };
                  };
              "40-me-${vlanName}" = lib.mkIf withMicroVMs (lib.mkDefault me);
            }
          );
        };

      };

    }

  ;
}
