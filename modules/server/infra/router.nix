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
      summersVLANs = selectVLANs [
        "home"
        "devices"
        "services"
      ];
      inherit (globals.general) homeDnsServer;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "router" ];
        topology.self.interfaces = lib.flip lib.concatMapAttrs globals.networks.home-lan.vlans (
          vlanName: _:
          lib.genAttrs [ "vlan-${vlanName}" "me-${vlanName}" ] (_: {
            network = lib.mkForce vlanName;
          })
        );
        globals.monitoring.systemd = confLib.mkSystemdMonitoring {
          serviceName = "avahi-${config.node.name}";
          unit = "avahi-daemon.service";
        };
        users.persistentIds.avahi = confLib.mkIds 978;
        services = {
          avahi = {
            enable = true;
            openFirewall = true;
            settings.reflector.enable-reflector = true;
          };
          resolved.settings.Resolve = {
            FallbackDNS = [
              "1.1.1.1"
              "9.9.9.9"
            ];
            MulticastDNS = "no";
          };
        };
        boot.kernel.sysctl = {
          "net.ipv4.conf.all.forwarding" = true;
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
                    "vlan-iot"
                  ];
                  verdict = "accept";
                };
                guests-to-fritzbox-lan = {
                  from = [ "vlan-guests" ];
                  to = [ "fritzbox-lan" ];
                  verdict = "reject";
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
                # Allow the services VLAN to reach our wireguard server and dhcpv6
                services-to-local = {
                  allowedUDPPorts = [
                    52829
                    547
                  ];
                  from = [ "vlan-services" ];
                  to = [ "local" ];
                };
                # Allow kde connect from wifi into home
                untrusted-to-kdeconnect = {
                  allowedTCPPortRanges = [
                    {
                      from = 1714;
                      to = 1764;
                    }
                  ];
                  allowedUDPPortRanges = [
                    {
                      from = 1714;
                      to = 1764;
                    }
                  ];
                  from = [ "untrusted" ];
                  to = [ "vlan-home" ];
                };
                # Allow printing/scanning from wifi
                untrusted-to-printer = {
                  allowedTCPPorts = [
                    80
                    631
                  ];
                  from = [ "untrusted" ];
                  to = [ "printer" ];
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
                fritzbox-lan = {
                  ipv4Addresses = [ globals.networks.home-lan.cidrv4 ];
                  ipv6Addresses = [ globals.networks.home-lan.cidrv6 ];
                  parent = "untrusted";
                };
                printer.ipv4Addresses = [
                  globals.networks.home-lan.vlans.devices.hosts.dell-C2665dnf-F49D60.ipv4
                ];
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
          //
            lib.mapAttrs'
              (
                lan: lanVLANs:
                lib.nameValuePair "30-${lan}" {
                  bridgeVLANs = lanVLANs;
                  linkConfig.RequiredForOnline = "enslaved";
                  matchConfig.MACAddress = config.repo.secrets.local.networking.networks.${lan}.mac;
                  networkConfig = {
                    Bridge = "br";
                    ConfigureWithoutCarrier = true;
                  };
                }
              )
              {
                # swBedroom
                lan1 = selectVLANs [
                  "home"
                  "devices"
                  "guests"
                ];
                # swKitchen
                lan2 = bridgeVLANs;
                # summers
                lan3 = summersVLANs;
                lan4 = summersVLANs;
                # swLivingRoom
                # TODO: remove services and reset ports 5+6 on swLR to guest when kitchen construction is finished
                lan5 = selectVLANs [
                  "home"
                  "devices"
                  "services"
                  "guests"
                ];
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
                  Managed = true;
                  OtherInformation = true;
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
    };
}
