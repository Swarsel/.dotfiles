{ self, lib, pkgs, config, ... }:
let
  certsSopsFile = self + /secrets/certs/secrets.yaml;
  clientSopsFile = self + /secrets/${config.networking.hostName}/secrets.yaml;

  inherit (config.swarselsystems) mainUser;
  inherit (config.repo.secrets.common.network) wlan1 wlan2 mobile1 vpn1-location vpn1-cipher vpn1-address eduroam-anon;
  inherit (config.repo.secrets.local.network) home-wireguard-address home-wireguard-allowed-ips;

  iwd = config.networking.networkmanager.wifi.backend == "iwd";
in
{
  options.swarselsystems = {
    modules.network = lib.mkEnableOption "network config";
    firewall = lib.swarselsystems.mkTrueOption;
  };
  config = lib.mkIf config.swarselsystems.modules.network {

    sops = {
      secrets = lib.mkIf (!config.swarselsystems.isPublic) {
        wlan1-pw = { };
        wlan2-pw = { };
        laptop-hotspot-pw = { };
        mobile-hotspot-pw = { };
        eduroam-user = { };
        eduroam-pw = { };
        pia-vpn-user = { };
        pia-vpn-pw = { };
        home-wireguard-client-private-key = { sopsFile = clientSopsFile; };
        home-wireguard-server-public-key = { };
        home-wireguard-endpoint = { };
        pia-vpn1-crl-pem = { sopsFile = certsSopsFile; };
        pia-vpn1-ca-pem = { sopsFile = certsSopsFile; };
      };
      templates = lib.mkIf (!config.swarselsystems.isPublic) {
        "network-manager.env".content = ''
          WLAN1_PW=${config.sops.placeholder.wlan1-pw}
          WLAN2_PW=${config.sops.placeholder.wlan2-pw}
          LAPTOP_HOTSPOT_PW=${config.sops.placeholder.laptop-hotspot-pw}
          MOBILE_HOTSPOT_PW=${config.sops.placeholder.mobile-hotspot-pw}
          EDUROAM_USER=${config.sops.placeholder.eduroam-user}
          EDUROAM_PW=${config.sops.placeholder.eduroam-pw}
          PIA_VPN_USER=${config.sops.placeholder.pia-vpn-user}
          PIA_VPN_PW=${config.sops.placeholder.pia-vpn-pw}
          HOME_WIREGUARD_CLIENT_PRIVATE_KEY=${config.sops.placeholder.home-wireguard-client-private-key}
          HOME_WIREGUARD_SERVER_PUBLIC_KEY=${config.sops.placeholder.home-wireguard-server-public-key}
          HOME_WIREGUARD_ENDPOINT=${config.sops.placeholder.home-wireguard-endpoint}
        '';
      };
    };

    networking = {
      wireless.iwd = {
        enable = true;
        settings = {
          IPv6 = {
            Enabled = true;
          };
          Settings = {
            AutoConnect = true;
          };
          DriverQuirks = {
            UseDefaultInterface = true;
          };
        };
      };
      nftables.enable = lib.mkDefault true;
      enableIPv6 = lib.mkDefault true;
      firewall = {
        enable = lib.swarselsystems.mkStrong config.swarselsystems.firewall;
        checkReversePath = lib.mkDefault false;
        allowedUDPPorts = [ 51820 ]; # 51820: wireguard
        allowedTCPPortRanges = [
          { from = 1714; to = 1764; } # kde-connect
        ];
        allowedUDPPortRanges = [
          { from = 1714; to = 1764; } # kde-connect
        ];
      };

      networkmanager = {
        enable = true;
        wifi.backend = "iwd";
        plugins = [
          # list of plugins: https://search.nixos.org/packages?query=networkmanager-
          # docs https://networkmanager.dev/docs/vpn/
          pkgs.networkmanager-openconnect
          pkgs.networkmanager-openvpn
        ];
        ensureProfiles = lib.mkIf (!config.swarselsystems.isPublic) {
          environmentFiles = [
            "${config.sops.templates."network-manager.env".path}"
          ];
          profiles = {
            ${wlan1} = {
              connection = {
                id = wlan1;
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
                ssid = wlan1;
              };
              wifi-security = {
                auth-alg = "open";
                key-mgmt = "wpa-psk";
                psk = "WLAN1_PW";
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
                eap = if (!iwd) then "ttls;" else "peap;";
                identity = "$EDUROAM_USER";
                password = "$EDUROAM_PW";
                phase2-auth = "mschapv2";
                anonymous-identity = lib.mkIf iwd eduroam-anon;
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

            ${wlan2} = {
              connection = {
                id = wlan2;
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
                ssid = wlan2;
              };
              wifi-security = {
                key-mgmt = "wpa-psk";
                psk = "$WLAN2_PW";
              };
            };

            ${mobile1} = {
              connection = {
                id = mobile1;
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
                ssid = mobile1;
              };
              wifi-security = {
                auth-alg = "open";
                key-mgmt = "wpa-psk";
                psk = "$MOBILE_HOTSPOT_PW";
              };
            };

            home-wireguard = {
              connection = {
                id = "HomeVPN";
                type = "wireguard";
                autoconnect = "false";
                interface-name = "wg1";
              };
              wireguard = { private-key = "$HOME_WIREGUARD_CLIENT_PRIVATE_KEY"; };
              "wireguard-peer.$HOME_WIREGURARD_SERVER_PUBLIC_KEY" = {
                endpoint = "$HOME_WIREGUARD_ENDPOINT";
                allowed-ips = home-wireguard-allowed-ips;
              };
              ipv4 = {
                method = "ignore";
                address1 = home-wireguard-address;
              };
              ipv6 = {
                addr-gen-mode = "stable-privacy";
                method = "ignore";
              };
              proxy = { };
            };

            pia-vpn1 = {
              connection = {
                autoconnect = "false";
                id = "PIA ${vpn1-location}";
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
                ca = config.sops.secrets."pia-vpn1-ca-pem".path;
                challenge-response-flags = "2";
                cipher = vpn1-cipher;
                compress = "yes";
                connection-type = "password";
                crl-verify-file = config.sops.secrets."pia-vpn1-crl-pem".path;
                dev = "tun";
                password-flags = "0";
                remote = vpn1-address;
                remote-cert-tls = "server";
                reneg-seconds = "0";
                service-type = "org.freedesktop.NetworkManager.openvpn";
                username = "$PIA_VPN_USER";
              };
              vpn-secrets = { password = "$PIA_VPN_PW"; };
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
                ssid = "Hotspot-${config.swarselsystems.mainUser}";
              };
              wifi-security = {
                group = "ccmp;";
                key-mgmt = "wpa-psk";
                pairwise = "ccmp;";
                proto = "rsn;";
                psk = "$MOBILE_HOTSPOT_PW";
              };
            };

          };
        };
      };
    };

    systemd.services.NetworkManager-ensure-profiles.after = [ "NetworkManager.service" ];
  };
}
