{
  flake.modules = {
    homeManager.network-manager-applet = {
      config = {
        swarselsystems.enabledHomeModules = [ "nm-applet" ];
        services.network-manager-applet.enable = true;
        xsession.preferStatusNotifierItems = true; # needed for indicator icon to show
      };
    };
    nixos.network =
      {
        self,
        config,
        lib,
        pkgs,
        confLib,
        ...
      }:
      let
        certsSopsFile = self + /secrets/repo/certs.yaml;
        clientSopsFile = config.node.secretsDir + "/secrets.yaml";

        inherit (config.repo.secrets.common.network)
          eduroam-anon
          mobile1
          vpn1-address
          vpn1-cipher
          vpn1-location
          wlan1
          ;

        iwd = config.networking.networkmanager.wifi.backend == "iwd";
      in
      {
        options.swarselsystems = {
          firewall = lib.swarselsystems.mkTrueOption;
        };
        config = {

          sops = {
            secrets = lib.mkIf (!config.swarselsystems.isPublic) {
              eduroam-pw = { };
              eduroam-user = { };
              home-wireguard-client-private-key = {
                sopsFile = clientSopsFile;
              };
              home-wireguard-endpoint = { };
              home-wireguard-server-public-key = { };
              laptop-hotspot-pw = { };
              mobile-hotspot-pw = { };
              pia-vpn-pw = { };
              pia-vpn-user = { };
              pia-vpn1-ca-pem = {
                sopsFile = certsSopsFile;
              };
              pia-vpn1-crl-pem = {
                sopsFile = certsSopsFile;
              };
              wlan1-pw = { };
              wlan2-pw = { };
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
          users.persistentIds = {
            nm-iodine = confLib.mkIds 957;
          };
          services.resolved.enable = true;
          networking = {
            enableIPv6 = lib.mkDefault true;
            firewall = {
              enable = lib.swarselsystems.mkStrong config.swarselsystems.firewall;
              allowedTCPPortRanges = [
                {
                  from = 1714;
                  to = 1764;
                } # kde-connect
              ];
              allowedUDPPortRanges = [
                {
                  from = 1714;
                  to = 1764;
                } # kde-connect
              ];
              allowedUDPPorts = [ 51820 ]; # 51820: wireguard
              checkReversePath = lib.mkDefault false;
            };
            hostName = config.node.name;
            hosts = { };
            networkmanager = {
              enable = true;
              dns = "systemd-resolved";
              ensureProfiles = lib.mkIf (!config.swarselsystems.isPublic) {
                environmentFiles = [
                  "${config.sops.templates."network-manager.env".path}"
                ];
                profiles =
                  let
                    inherit (config.repo.secrets.local.network) home-wireguard-address home-wireguard-allowed-ips;
                  in
                  {
                    ${mobile1} = {
                      connection = {
                        autoconnect-priority = "500";
                        id = mobile1;
                        type = "wifi";
                      };
                      ipv4 = {
                        method = "auto";
                      };
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
                    ${wlan1} = {
                      connection = {
                        autoconnect-priority = "999";
                        id = wlan1;
                        # permissions = "";
                        type = "wifi";
                      };
                      ipv4 = {
                        # dns-search = "";
                        method = "auto";
                      };
                      ipv6 = {
                        addr-gen-mode = "stable-privacy";
                        # dns-search = "";
                        method = "auto";
                      };
                      wifi = {
                        # mac-address-blacklist = "";
                        mode = "infrastructure";
                        # band = "a";
                        ssid = wlan1;
                      };
                      wifi-security = {
                        # auth-alg = "open";
                        key-mgmt = "wpa-psk";
                        psk = "$WLAN1_PW";
                      };
                    };
                    Hotspot = {
                      connection = {
                        autoconnect = "false";
                        id = "Hotspot";
                        type = "wifi";
                      };
                      ipv4 = {
                        method = "shared";
                      };
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
                      ipv4 = {
                        method = "shared";
                      };
                      ipv6 = {
                        addr-gen-mode = "stable-privacy";
                        method = "auto";
                      };
                      proxy = { };
                    };
                    eduroam = {
                      "802-1x" = {
                        anonymous-identity = lib.mkIf iwd eduroam-anon;
                        eap = if (!iwd) then "ttls;" else "peap;";
                        identity = "$EDUROAM_USER";
                        password = "$EDUROAM_PW";
                        phase2-auth = "mschapv2";
                      };
                      connection = {
                        id = "eduroam";
                        type = "wifi";
                      };
                      ipv4 = {
                        method = "auto";
                      };
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
                    home-wireguard = {
                      connection = {
                        autoconnect = "false";
                        id = "HomeVPN";
                        interface-name = "wg1";
                        type = "wireguard";
                      };
                      ipv4 = {
                        address1 = home-wireguard-address;
                        method = "ignore";
                      };
                      ipv6 = {
                        addr-gen-mode = "stable-privacy";
                        method = "ignore";
                      };
                      proxy = { };
                      wireguard = {
                        private-key = "$HOME_WIREGUARD_CLIENT_PRIVATE_KEY";
                      };
                      "wireguard-peer.$HOME_WIREGURARD_SERVER_PUBLIC_KEY" = {
                        allowed-ips = home-wireguard-allowed-ips;
                        endpoint = "$HOME_WIREGUARD_ENDPOINT";
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
                    pia-vpn1 = {
                      connection = {
                        autoconnect = "false";
                        id = "PIA ${vpn1-location}";
                        type = "vpn";
                      };
                      ipv4 = {
                        method = "auto";
                      };
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
                      vpn-secrets = {
                        password = "$PIA_VPN_PW";
                      };
                    };

                  };
              };
              plugins = [
                # list of plugins: https://search.nixos.org/packages?query=networkmanager-
                # docs https://networkmanager.dev/docs/vpn/
                pkgs.networkmanager-openconnect
                pkgs.networkmanager-openvpn
              ];
              wifi.backend = "iwd";
            };
            nftables.enable = lib.mkDefault true;
            wireless.iwd = {
              enable = true;
              settings = {
                IPv6 = {
                  Enabled = true;
                };
                Settings = {
                  AutoConnect = true;
                };
                # DriverQuirks = {
                #   UseDefaultInterface = true;
                # };
              };
            };
          };
          systemd.services.NetworkManager-ensure-profiles.after = [ "NetworkManager.service" ];
        };
      };
  };
}
