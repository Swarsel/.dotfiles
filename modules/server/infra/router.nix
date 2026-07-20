{
  flake.modules.nixos.router =
    {
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      bridgeVLANs = lib.mapAttrsToList (_: vlan: {
        VLAN = vlan.id;
      }) globals.networks.home-lan.vlans;
      selectVLANs = vlans: map (vlan: { VLAN = globals.networks.home-lan.vlans.${vlan}.id; }) vlans;
      lan1VLANs = selectVLANs [
        "home"
        "devices"
        "guests"
      ];
      lan2VLANs = selectVLANs [
        "home"
        "devices"
        "services"
      ];
      lan3VLANs = selectVLANs [
        "home"
        "devices"
        "services"
      ];
      lan4VLANs = lan3VLANs;
      # TODO: remove services and reset ports 5+6 on swLR to guest when kitchen construction is finished
      lan5VLANs = selectVLANs [
        "home"
        "devices"
        "services"
        "guests"
      ];
      inherit (globals.general) homeDnsServer;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "router" ];
        topology.self.interfaces =
          (lib.mapAttrs' (
            vlanName: _:
            lib.nameValuePair "vlan-${vlanName}" {
              network = lib.mkForce vlanName;
            }
          ) globals.networks.home-lan.vlans)
          // (lib.mapAttrs' (
            vlanName: _:
            lib.nameValuePair "me-${vlanName}" {
              network = lib.mkForce vlanName;
            }
          ) globals.networks.home-lan.vlans);
        users.persistentIds.avahi = confLib.mkIds 978;
        services = {
          avahi = {
            enable = true;
            openFirewall = true;
            reflector = true;
          };
          resolved = {
            fallbackDns = [
              "1.1.1.1"
              "9.9.9.9"
            ];
            settings.Resolve.MulticastDNS = "no";
          };
        };
        boot.kernel.sysctl = {
          "net.ipv4.conf.all.forwarding" = true;
          "net.ipv4.ip_forward" = 1;
          "net.ipv6.conf.all.forwarding" = true;
        };
        networking = {
          nameservers = [
            globals.networks.home-lan.vlans.services.hosts.${homeDnsServer}.ipv4
            globals.networks.home-lan.vlans.services.hosts.${homeDnsServer}.ipv6
          ];
          nftables = {
            chains.postrouting.masquerade-internet = {
              after = [ "hook" ];
              late = true;
              rules = lib.forEach (map (name: "vlan-${name}") globals.general.internetVLANs) (
                zone:
                lib.concatStringsSep " " [
                  "meta protocol { ip, ip6 }"
                  (lib.head config.networking.nftables.firewall.zones.${zone}.ingressExpression)
                  (lib.head config.networking.nftables.firewall.zones.untrusted.egressExpression)
                  "masquerade random"
                ]
              );
            };
            firewall = {
              rules = {
                # Allow access to the AdGuardHome DNS server from any VLAN that has internet access
                access-adguardhome-dns = {
                  from = map (name: "vlan-${name}") globals.general.internetVLANs;
                  to = [ "adguardhome" ];
                  verdict = "accept";
                };
                # Allow devices in the home VLAN to talk to any of the services or home devices.
                access-services = {
                  from = [ "vlan-home" ];
                  late = true;
                  to = [
                    "vlan-services"
                    "vlan-devices"
                  ];
                  verdict = "accept";
                };
                masquerade-internet = {
                  from = map (name: "vlan-${name}") globals.general.internetVLANs;
                  # masquerade = true; NOTE: custom rule above for ip4 + ip6
                  late = true; # Only accept after any rejects have been processed
                  to = [ "untrusted" ];
                  verdict = "accept";
                };
                # Allow mDNS from any VLAN (plus FritzBox-LAN) into the router
                mdns-to-local = {
                  allowedUDPPorts = [ 5353 ];
                  from = [
                    "vlan-services"
                    "vlan-home"
                    "vlan-devices"
                    "vlan-guests"
                    "untrusted"
                  ];
                  to = [ "local" ];
                };
                # Allow the services VLAN to talk to our wireguard server
                services-to-local = {
                  allowedUDPPorts = [
                    52829
                    547
                  ];
                  from = [ "vlan-services" ];
                  to = [ "local" ];
                };

              };
              zones = {
                adguardhome = {
                  ipv4Addresses = [
                    globals.networks.home-lan.vlans.services.hosts.${homeDnsServer}.ipv4
                  ];
                  ipv6Addresses = [
                    globals.networks.home-lan.vlans.services.hosts.${homeDnsServer}.ipv6
                  ];
                };
                untrusted.interfaces = [ "lan" ];
                wgHome.interfaces = [ "wgHome" ];
              }
              // lib.flip lib.concatMapAttrs globals.networks.home-lan.vlans (
                vlanName: _: {
                  "vlan-${vlanName}".interfaces = [ "me-${vlanName}" ];
                }
              );
            };
          };
        };
        systemd.network = {
          netdevs = {
            "10-veth" = {
              netdevConfig = {
                Kind = "veth";
                Name = "veth-br";
              };
              peerConfig.Name = "veth-int";
            };
            "20-br" = {
              bridgeConfig.VLANFiltering = true;
              netdevConfig = {
                Kind = "bridge";
                Name = "br";
              };
            };
          };
          networks = {
            "15-veth-br" = {
              inherit bridgeVLANs;
              linkConfig.RequiredForOnline = "no";
              matchConfig.Name = "veth-br";
              networkConfig.Bridge = "br";
            };
            "15-veth-int" = {
              linkConfig = {
                ActivationPolicy = "always-up";
                RequiredForOnline = "no";
              };
              matchConfig.Name = "veth-int";
              networkConfig = {
                ConfigureWithoutCarrier = true;
                LinkLocalAddressing = "no";
              };
              vlan = map (name: "vlan-${name}") (builtins.attrNames globals.networks.home-lan.vlans);
            };
            # br
            "30-lan1" = {
              bridgeVLANs = lan1VLANs;
              linkConfig.RequiredForOnline = "enslaved";
              matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan1.mac;
              networkConfig = {
                Bridge = "br";
                ConfigureWithoutCarrier = true;
              };
            };
            # winters
            "30-lan2" = {
              bridgeVLANs = lan2VLANs;
              linkConfig.RequiredForOnline = "enslaved";
              matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan2.mac;
              networkConfig = {
                Bridge = "br";
                ConfigureWithoutCarrier = true;
              };
            };
            # summers
            "30-lan3" = {
              bridgeVLANs = lan3VLANs;
              linkConfig.RequiredForOnline = "enslaved";
              matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan3.mac;
              networkConfig = {
                Bridge = "br";
                ConfigureWithoutCarrier = true;
              };
            };
            # summers
            "30-lan4" = {
              bridgeVLANs = lan4VLANs;
              linkConfig.RequiredForOnline = "enslaved";
              matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan4.mac;
              networkConfig = {
                Bridge = "br";
                ConfigureWithoutCarrier = true;
              };
            };
            # lr
            "30-lan5" = {
              bridgeVLANs = lan5VLANs;
              linkConfig.RequiredForOnline = "enslaved";
              matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan5.mac;
              networkConfig = {
                Bridge = "br";
                ConfigureWithoutCarrier = true;
              };
            };
            "40-br" = {
              bridgeConfig = { };
              linkConfig = {
                ActivationPolicy = "always-up";
                RequiredForOnline = "no";
              };
              matchConfig.Name = "br";
              networkConfig = {
                ConfigureWithoutCarrier = true;
                LinkLocalAddressing = "no";
              };
            };
          }
          // lib.flip lib.concatMapAttrs globals.networks.home-lan.vlans (
            vlanName: vlanCfg: {
              "40-me-${vlanName}" = lib.mkForce {
                address = [
                  vlanCfg.hosts.${config.node.name}.cidrv4
                  vlanCfg.hosts.${config.node.name}.cidrv6
                ];
                ipv6Prefixes = [
                  {
                    Prefix = vlanCfg.cidrv6;
                  }
                ];
                ipv6SendRAConfig = {
                  Managed = true; # set RA M flag -> DHCPv6 for addresses
                  OtherInformation = true; # optional, for “other info” via DHCPv6
                };
                linkConfig.RequiredForOnline = "routable";
                matchConfig.Name = "me-${vlanName}";
                networkConfig = {
                  IPv4Forwarding = "yes";
                  IPv6AcceptRA = false;
                  IPv6PrivacyExtensions = "yes";
                  IPv6SendRA = true;
                };
              };
            }
          );
          wait-online.anyInterface = true;

        };

      };
    }

  ;
}
