{
  flake.modules = {
    homeManager.network-manager-applet.config = {
      swarselsystems.enabledHomeModules = [ "nm-applet" ];
      services.network-manager-applet.enable = true;
      xsession.preferStatusNotifierItems = true; # needed for indicator icon to show
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
      in
      {
        options.swarselsystems.firewall = lib.swarselsystems.mkTrueOption;
        config = {

          sops = {
            secrets = lib.mkIf (!config.swarselsystems.isPublic) {
              eduroam-pw = { };
              eduroam-user = { };
              home-wireguard-client-private-key.sopsFile = clientSopsFile;
              home-wireguard-endpoint = { };
              home-wireguard-preshared-key.sopsFile = clientSopsFile;
              home-wireguard-server-public-key = { };
              laptop-hotspot-pw = { };
              mobile-hotspot-pw = { };
              pia-vpn-pw = { };
              pia-vpn-user = { };
              pia-vpn1-ca-pem = {
                mode = "0444";
                sopsFile = certsSopsFile;
              };
              wlan1-pw = { };
              wlan2-pw = { };
              wlan3-pw = { };
            };
            templates = lib.mkIf (!config.swarselsystems.isPublic) {
              "network-manager.env".content = ''
                WLAN1_PW=${config.sops.placeholder.wlan1-pw}
                WLAN2_PW=${config.sops.placeholder.wlan2-pw}
                WLAN3_PW=${config.sops.placeholder.wlan3-pw}
                LAPTOP_HOTSPOT_PW=${config.sops.placeholder.laptop-hotspot-pw}
                MOBILE_HOTSPOT_PW=${config.sops.placeholder.mobile-hotspot-pw}
                EDUROAM_USER=${config.sops.placeholder.eduroam-user}
                EDUROAM_PW=${config.sops.placeholder.eduroam-pw}
                PIA_VPN_USER=${config.sops.placeholder.pia-vpn-user}
                PIA_VPN_PW=${config.sops.placeholder.pia-vpn-pw}
                HOME_WIREGUARD_CLIENT_PRIVATE_KEY=${config.sops.placeholder.home-wireguard-client-private-key}
                HOME_WIREGUARD_PRESHARED_KEY=${config.sops.placeholder.home-wireguard-preshared-key}
                HOME_WIREGUARD_SERVER_PUBLIC_KEY=${config.sops.placeholder.home-wireguard-server-public-key}
                HOME_WIREGUARD_ENDPOINT=${config.sops.placeholder.home-wireguard-endpoint}
              '';
            };
          };
          users.persistentIds.nm-iodine = confLib.mkIds 957;
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
                profiles = config.repo.secrets.common.network.profiles;
              };
              plugins = [
                # list of plugins: https://search.nixos.org/packages?query=networkmanager-
                # docs https://networkmanager.dev/docs/vpn/
                pkgs.networkmanager-openconnect
                pkgs.networkmanager-openvpn
              ];
              settings.main.no-auto-default = "*";
              wifi.backend = "iwd";
            };
            nftables.enable = lib.mkDefault true;
            wireless.iwd = {
              enable = true;
              settings = {
                IPv6.Enabled = true;
                Settings.AutoConnect = true;
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
