{ lib, config, globals, confLib, ... }:
let
  serviceName = "router";
  bridgeVLANs = lib.mapAttrsToList
    (_: vlan: {
      VLAN = vlan.id;
    })
    globals.networks.home-lan.vlans;
  selectVLANs = vlans: map (vlan: { VLAN = globals.networks.home-lan.vlans.${vlan}.id; }) vlans;
  lan5VLANs = selectVLANs [ "home" "devices" "guests" ];
  lan4VLANs = selectVLANs [ "home" "services" ];
  inherit (confLib.gen { }) homeDnsServer;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName}
    {
      services.avahi.reflector = true;

      topology.self.interfaces = (lib.mapAttrs'
        (vlanName: _:
          lib.nameValuePair "vlan-${vlanName}" {
            network = lib.mkForce vlanName;
          }
        )
        globals.networks.home-lan.vlans) // (lib.mapAttrs'
        (vlanName: _:
          lib.nameValuePair "me-${vlanName}" {
            network = lib.mkForce vlanName;
          }
        )
        globals.networks.home-lan.vlans);

      networking.nftables = {
        firewall = {
          zones = {
            untrusted.interfaces = [ "lan" ];
            wgHome.interfaces = [ "wgHome" ];
            adguardhome.ipv4Addresses = [ globals.networks.home-lan.vlans.services.hosts.${homeDnsServer}.ipv4 ];
            adguardhome.ipv6Addresses = [ globals.networks.home-lan.vlans.services.hosts.${homeDnsServer}.ipv6 ];
          }
          // lib.flip lib.concatMapAttrs globals.networks.home-lan.vlans (
            vlanName: _: {
              "vlan-${vlanName}".interfaces = [ "me-${vlanName}" ];
            }
          );

          rules = {
            masquerade-internet = {
              from = map (name: "vlan-${name}") (globals.general.internetVLANs);
              to = [ "untrusted" ];
              # masquerade = true; NOTE: custom rule below for ip4 + ip6
              late = true; # Only accept after any rejects have been processed
              verdict = "accept";
            };

            # Allow access to the AdGuardHome DNS server from any VLAN that has internet access
            access-adguardhome-dns = {
              from = map (name: "vlan-${name}") (globals.general.internetVLANs);
              to = [ "adguardhome" ];
              verdict = "accept";
            };

            # Allow devices in the home VLAN to talk to any of the services or home devices.
            access-services = {
              from = [ "vlan-home" ];
              to = [
                "vlan-services"
                "vlan-devices"
              ];
              late = true;
              verdict = "accept";
            };

            # Allow the services VLAN to talk to our wireguard server
            services-to-local = {
              from = [ "vlan-services" ];
              to = [ "local" ];
              allowedUDPPorts = [ 52829 547 ];
            };

            # Forward traffic between wireguard participants
            forward-proxy-home-vpn-traffic = {
              from = [ "wgHome" ];
              to = [ "wgHome" ];
              verdict = "accept";
            };
          };
        };

        chains.postrouting = {
          masquerade-internet = {
            after = [ "hook" ];
            late = true;
            rules =
              lib.forEach
                (map (name: "vlan-${name}") (globals.general.internetVLANs))
                (
                  zone:
                  lib.concatStringsSep " " [
                    "meta protocol { ip, ip6 }"
                    (lib.head config.networking.nftables.firewall.zones.${zone}.ingressExpression)
                    (lib.head config.networking.nftables.firewall.zones.untrusted.egressExpression)
                    "masquerade random"
                  ]
                );
          };
        };
      };

      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
      };

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
            bridgeConfig = {
              VLANFiltering = true;
            };
          };
        };
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
            inherit bridgeVLANs;
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
          # br
          "30-lan1" = {
            matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan1.mac;
            linkConfig.RequiredForOnline = "enslaved";
            networkConfig = {
              Bridge = "br";
              ConfigureWithoutCarrier = true;
            };
            inherit bridgeVLANs;
          };
          # wifi
          "30-lan2" = {
            matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan2.mac;
            linkConfig.RequiredForOnline = "enslaved";
            networkConfig = {
              Bridge = "br";
              ConfigureWithoutCarrier = true;
            };
            inherit bridgeVLANs;
          };
          # summers
          "30-lan3" = {
            matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan3.mac;
            linkConfig.RequiredForOnline = "enslaved";
            networkConfig = {
              Bridge = "br";
              ConfigureWithoutCarrier = true;
            };
            inherit bridgeVLANs;
          };
          # winters
          "30-lan4" = {
            matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan4.mac;
            linkConfig.RequiredForOnline = "enslaved";
            networkConfig = {
              Bridge = "br";
              ConfigureWithoutCarrier = true;
            };
            bridgeVLANs = lan4VLANs;
          };
          # lr
          "30-lan5" = {
            matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan5.mac;
            linkConfig.RequiredForOnline = "enslaved";
            networkConfig = {
              Bridge = "br";
              ConfigureWithoutCarrier = true;
            };
            bridgeVLANs = lan5VLANs;
          };
        } // lib.flip lib.concatMapAttrs globals.networks.home-lan.vlans (
          vlanName: vlanCfg: {
            "40-me-${vlanName}" = lib.mkForce {
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
                {
                  Prefix = vlanCfg.cidrv6;
                }
              ];
              ipv6SendRAConfig = {
                Managed = true; # set RA M flag -> DHCPv6 for addresses
                OtherInformation = true; # optional, for “other info” via DHCPv6
              };
              linkConfig.RequiredForOnline = "routable";
            };
          }
        );

      };

    };
}
