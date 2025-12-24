{ lib, config, globals, ... }:
let
  serviceName = "router";
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName}
    {
      services.avahi.reflector = true;

      networking.nftables = {
        firewall = {
          zones = {
            untrusted.interfaces = [ "lan" ];
            wgHome.interfaces = [ "wgHome" ];
            adguardhome.ipv4Addresses = [ globals.networks.home-lan.vlans.services.hosts.hintbooth-adguardhome.ipv4 ];
            adguardhome.ipv6Addresses = [ globals.networks.home-lan.vlans.services.hosts.hintbooth-adguardhome.ipv6 ];
          }
          // lib.flip lib.concatMapAttrs globals.networks.home-lan.vlans (
            vlanName: _: {
              "vlan-${vlanName}".interfaces = [ "me-${vlanName}" ];
            }
          );

          rules = {
            masquerade-internet = {
              from = map (name: "vlan-${name}") (builtins.attrNames globals.networks.home-lan.vlans);
              to = [ "untrusted" ];
              # masquerade = true; NOTE: custom rule below for ip4 + ip6
              late = true; # Only accept after any rejects have been processed
              verdict = "accept";
            };

            # Allow access to the AdGuardHome DNS server from any VLAN that has internet access
            access-adguardhome-dns = {
              from = map (name: "vlan-${name}") (builtins.attrNames globals.networks.home-lan.vlans);
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
              allowedUDPPorts = [ 52829 ];
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
                (map (name: "vlan-${name}") (builtins.attrNames globals.networks.home-lan.vlans))
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
        networks = {
          "30-lan1" = {
            matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan1.mac;
            linkConfig.RequiredForOnline = "enslaved";
            networkConfig = {
              Bridge = "br";
              ConfigureWithoutCarrier = true;
            };
          };
          "30-lan2" = {
            matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan2.mac;
            linkConfig.RequiredForOnline = "enslaved";
            networkConfig = {
              Bridge = "br";
              ConfigureWithoutCarrier = true;
            };
          };
          "30-lan3" = {
            matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan3.mac;
            linkConfig.RequiredForOnline = "enslaved";
            networkConfig = {
              Bridge = "br";
              ConfigureWithoutCarrier = true;
            };
          };
          "30-lan4" = {
            matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan4.mac;
            linkConfig.RequiredForOnline = "enslaved";
            networkConfig = {
              Bridge = "br";
              ConfigureWithoutCarrier = true;
            };
          };
          "30-lan5" = {
            matchConfig.MACAddress = config.repo.secrets.local.networking.networks.lan5.mac;
            linkConfig.RequiredForOnline = "enslaved";
            networkConfig = {
              Bridge = "br";
              ConfigureWithoutCarrier = true;
            };
          };
        };
      };


    };
}
