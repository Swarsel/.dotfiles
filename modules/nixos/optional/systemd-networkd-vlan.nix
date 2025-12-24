{ lib, config, globals, ... }:
{

  systemd.network = {
    wait-online.anyInterface = true;
    netdevs = {
      "10-veth" = {
        netdevConfig = {
          Kind = "veth";
          Name = "veth-br";
        };
        peerConfig = {
          Name = "veth-int";
        };
      };
      "20-br" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br";
        };
      };
    } // lib.flip lib.concatMapAttrs globals.networks.home-lan.vlans (
      vlanName: vlanCfg: {
        "30-vlan-${vlanName}" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "vlan-${vlanName}";
          };
          vlanConfig.Id = vlanCfg.id;
        };
        "40-me-${vlanName}" = {
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
      "40-br" = {
        matchConfig.Name = "br";
        bridgeConfig = { };
        linkConfig = {
          ActivationPolicy = "always-up";
          RequiredForOnline = "no";
        };
        networkConfig = {
          ConfigureWithoutCarrier = true;
          LinkLocalAddressing = "no";
        };
      };
      "15-veth-br" = {
        matchConfig.Name = "veth-br";

        linkConfig = {
          RequiredForOnline = "no";
        };

        networkConfig = {
          Bridge = "br";
        };
      };
      "15-veth-int" = {
        matchConfig.Name = "veth-int";

        linkConfig = {
          ActivationPolicy = "always-up";
          RequiredForOnline = "no";
        };

        networkConfig = {
          ConfigureWithoutCarrier = true;
          LinkLocalAddressing = "no";
        };

        vlan = map (name: "vlan-${name}") (builtins.attrNames globals.networks.home-lan.vlans);
      };
      "90-macvtap-ignore" = {
        matchConfig.Kind = "macvtap";
        linkConfig.ActivationPolicy = "manual";
        linkConfig.Unmanaged = "yes";
      };
    } // lib.flip lib.concatMapAttrs globals.networks.home-lan.vlans (
      vlanName: vlanCfg: {
        "30-vlan-${vlanName}" = {
          matchConfig.Name = "vlan-${vlanName}";
          networkConfig.LinkLocalAddressing = "no";
          networkConfig.MACVLAN = "me-${vlanName}";
          linkConfig.RequiredForOnline = "no";
        };
        "40-me-${vlanName}" = {
          address = [
            vlanCfg.hosts.${config.node.name}.cidrv4
            vlanCfg.hosts.${config.node.name}.cidrv6
          ];
          matchConfig.Name = "me-${vlanName}";
          networkConfig = {
            IPv4Forwarding = "yes";
            IPv6PrivacyExtensions = "yes";
            IPv6SendRA = true;
            IPv6AcceptRA = false;
          };
          ipv6Prefixes = [
            { Prefix = vlanCfg.cidrv6; }
          ];
          linkConfig.RequiredForOnline = "routable";
        };
      }
    );
  };

}
