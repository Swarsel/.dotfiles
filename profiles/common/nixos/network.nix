{ lib, config, ... }:
{
  networking = {
    nftables.enable = lib.mkDefault true;
    enableIPv6 = lib.mkDefault true;
    firewall = {
      checkReversePath = lib.mkDefault false;
      enable = lib.mkDefault true;
      allowedUDPPorts = [ 51820 ]; # 34197: factorio; 4380 27036 14242: barotrauma; 51820: wireguard
    };

    networkmanager = {
      enable = true;
      ensureProfiles = {
        environmentFiles = [
          "${config.sops.templates."network-manager.env".path}"
        ];
        profiles = {
          "Ernest Routerford" = {
            connection = {
              id = "Ernest Routerford";
              permissions = "";
              type = "wifi";
            };
            ipv4 = {
              dns-search = "";
              method = "auto";
            };
            ipv6 = {
              addr-gen-mode = "stable-privacy";
              dns-search = "";
              method = "auto";
            };
            wifi = {
              mac-address-blacklist = "";
              mode = "infrastructure";
              ssid = "Ernest Routerford";
            };
            wifi-security = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk = "$ERNEST";
            };
          };

          LAN-Party = {
            connection = {
              autoconnect = "false";
              id = "LAN-Party";
              type = "ethernet";
            };
            ethernet = {
              auto-negotiate = "true";
              cloned-mac-address = "preserve";
              mac-address = "90:2E:16:D0:A1:87";
            };
            ipv4 = { method = "shared"; };
            ipv6 = {
              addr-gen-mode = "stable-privacy";
              method = "auto";
            };
            proxy = { };
          };

          eduroam = {
            "802-1x" = {
              eap = "ttls;";
              identity = "$EDUID";
              password = "$EDUPASS";
              phase2-auth = "mschapv2";
            };
            connection = {
              id = "eduroam";
              type = "wifi";
            };
            ipv4 = { method = "auto"; };
            ipv6 = {
              addr-gen-mode = "default";
              method = "auto";
            };
            proxy = { };
            wifi = {
              mode = "infrastructure";
              ssid = "eduroam";
            };
            wifi-security = {
              auth-alg = "open";
              key-mgmt = "wpa-eap";
            };
          };

          local = {
            connection = {
              autoconnect = "false";
              id = "local";
              type = "ethernet";
            };
            ethernet = { };
            ipv4 = {
              address1 = "10.42.1.1/24";
              method = "shared";
            };
            ipv6 = {
              addr-gen-mode = "stable-privacy";
              method = "auto";
            };
            proxy = { };
          };

          HH40V_39F5 = {
            connection = {
              id = "HH40V_39F5";
              type = "wifi";
            };
            ipv4 = { method = "auto"; };
            ipv6 = {
              addr-gen-mode = "stable-privacy";
              method = "auto";
            };
            proxy = { };
            wifi = {
              band = "bg";
              mode = "infrastructure";
              ssid = "HH40V_39F5";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$FRAUNS";
            };
          };

          magicant = {
            connection = {
              id = "magicant";
              type = "wifi";
            };
            ipv4 = { method = "auto"; };
            ipv6 = {
              addr-gen-mode = "default";
              method = "auto";
            };
            proxy = { };
            wifi = {
              mode = "infrastructure";
              ssid = "magicant";
            };
            wifi-security = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk = "$HANDYHOTSPOT";
            };
          };

          wireguardvpn = {
            connection = {
              id = "HomeVPN";
              type = "wireguard";
              autoconnect = "false";
              interface-name = "wg1";
            };
            wireguard = { private-key = "$WIREGUARDPRIV"; };
            "wireguard-peer.$WIREGUARDPUB" = {
              endpoint = "$WIREGUARDENDPOINT";
              allowed-ips = "0.0.0.0/0";
            };
            ipv4 = {
              method = "ignore";
              address1 = "192.168.3.3/32";
            };
            ipv6 = {
              addr-gen-mode = "stable-privacy";
              method = "ignore";
            };
            proxy = { };
          };

          "sweden-aes-128-cbc-udp-dns" = {
            connection = {
              autoconnect = "false";
              id = "PIA Sweden";
              type = "vpn";
            };
            ipv4 = { method = "auto"; };
            ipv6 = {
              addr-gen-mode = "stable-privacy";
              method = "auto";
            };
            proxy = { };
            vpn = {
              auth = "sha1";
              ca =
                "${config.users.users.swarsel.home}/.dotfiles/secrets/certs/sweden-aes-128-cbc-udp-dns-ca.pem";
              challenge-response-flags = "2";
              cipher = "aes-128-cbc";
              compress = "yes";
              connection-type = "password";
              crl-verify-file = "${config.users.users.swarsel.home}/.dotfiles/secrets/certs/sweden-aes-128-cbc-udp-dns-crl-verify.pem";
              dev = "tun";
              password-flags = "0";
              remote = "sweden.privacy.network:1198";
              remote-cert-tls = "server";
              reneg-seconds = "0";
              service-type = "org.freedesktop.NetworkManager.openvpn";
              username = "$VPNUSER";
            };
            vpn-secrets = { password = "$VPNPASS"; };
          };

          Hotspot = {
            connection = {
              autoconnect = "false";
              id = "Hotspot";
              type = "wifi";
            };
            ipv4 = { method = "shared"; };
            ipv6 = {
              addr-gen-mode = "default";
              method = "ignore";
            };
            proxy = { };
            wifi = {
              mode = "ap";
              ssid = "Hotspot-fourside";
            };
            wifi-security = {
              group = "ccmp;";
              key-mgmt = "wpa-psk";
              pairwise = "ccmp;";
              proto = "rsn;";
              psk = "$HOTSPOT";
            };
          };

        };
      };
    };
  };

  systemd.services.NetworkManager-ensure-profiles.after = [ "NetworkManager.service" ];
}
