{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.transmission {

    virtualisation.docker.enable = true;
    environment.systemPackages = with pkgs; [
      docker
    ];
    # boot = {
    #   kernelModules = [ "tun" ];
    #   kernel.sysctl = {
    #     "net.ipv4.conf.all.rp_filter" = 2;
    #     "net.ipv4.conf.default.rp_filter" = 2;
    #     "net.ipv4.conf.enp3s0.rp_filter" = 2;
    #   };
    # };
    # environment.systemPackages = with pkgs; [
    #   jq
    #   traceroute
    #   curl
    # ];
    # environment.etc = {
    #   "openvpn/iptables.sh" =
    #     {
    #       source = ../../../scripts/server1/iptables.sh;
    #       mode = "0755";
    #     };
    #   "openvpn/update-resolv-conf" =
    #     {
    #       source = ../../../scripts/server1/update-resolv-conf;
    #       mode = "0755";
    #     };
    #   "openvpn/routing.sh" =
    #     {
    #       source = ../../../scripts/server1/routing.sh;
    #       mode = "0755";
    #     };
    #   "openvpn/ca.rsa.2048.crt" =
    #     {
    #       source = ../../../secrets/certs/ca.rsa.2048.crt;
    #       mode = "0644";
    #     };
    #   "openvpn/crl.rsa.2048.pem" =
    #     {
    #       source = ../../../secrets/certs/crl.rsa.2048.pem;
    #       mode = "0644";
    #     };
    # };

    # networking = {
    #   firewall.extraCommands = ''
    #     sudo iptables -A OUTPUT ! -o lo -m owner --uid-owner vpn -j DROP
    #   '';
    #   iproute2 = {
    #     enable = true;
    #     rttablesExtraConfig = ''
    #       200     vpn
    #     '';
    #   };
    # };

    # users = {
    #   groups = {
    #     vpn = { };
    #   };
    #   users = {
    #     vpn = {
    #       isNormalUser = true;
    #       group = "vpn";
    #       home = "/home/vpn";
    #     };
    #   };
    # };

    # sops = {
    #   secrets = {
    #     vpnuser = { };
    #     rpcuser = { owner = "vpn"; };
    #     vpnpass = { };
    #     rpcpass = { owner = "vpn"; };
    #     vpnprot = { };
    #     vpnloc = { };
    #   };
    #   templates = {
    #     "transmission-rpc" = {
    #       owner = "vpn";
    #       content = builtins.toJSON {
    #         rpc-username = config.sops.placeholder.rpcuser;
    #         rpc-password = config.sops.placeholder.rpcpass;
    #       };
    #     };

    #     pia.content = ''
    #       ${config.sops.placeholder.vpnuser}
    #       ${config.sops.placeholder.vpnpass}
    #     '';

    #     vpn = {
    #       path = "/etc/openvpn/openvpn.conf";
    #       mode = "0644";
    #       content = ''
    #         client
    #         dev tun
    #         proto ${config.sops.placeholder.vpnprot}
    #         remote ${config.sops.placeholder.vpnloc}
    #         resolv-retry infinite
    #         nobind
    #         persist-key
    #         persist-tun
    #         cipher aes-128-cbc
    #         auth sha1
    #         tls-client
    #         remote-cert-tls server

    #         auth-user-pass ${config.sops.templates.pia.path}
    #         auth-nocache
    #         comp-lzo
    #         compress
    #         verb 1
    #         reneg-sec 0

    #         crl-verify /etc/openvpn/crl.rsa.2048.pem
    #         ca /etc/openvpn/ca.rsa.2048.crt

    #         disable-occ
    #         script-security 2
    #         route-noexec

    #         up /etc/openvpn/iptables.sh
    #         down /etc/openvpn/update-resolv-conf
    #       '';
    #     };
    #   };
    # };

    # systemd = {
    #   timers."restart-pia-monthly" = {
    #     wantedBy = [ "timers.target" ];
    #     timerConfig = {
    #       OnBootSec = "1M";
    #       OnUnitActiveSec = "1M";
    #       Unit = "restart-pia-monthly.service";
    #     };
    #   };

    #   services."restart-pia-monthly" = {
    #     script = ''
    #       systemctl restart pia-pf.service
    #     '';
    #     serviceConfig = {
    #       Type = "oneshot";
    #       User = "root";
    #     };
    #   };

    #   timers."reboot-portforward-2h" = {
    #     wantedBy = [ "timers.target" ];
    #     timerConfig = {
    #       OnBootSec = "2h";
    #       OnUnitActiveSec = "2h";
    #       Unit = "reboot-portforward-2h.service";
    #     };
    #   };

    #   services."reboot-portforward-2h" = {
    #     script = ''
    #       /etc/openvpn/portforward.sh | while IFS= read -r line; do echo "$(date) $line"; done >> /var/log/pia_portforward.log 2>&1
    #     '';
    #     serviceConfig = {
    #       Type = "oneshot";
    #       User = "root";
    #     };
    #   };

    #   timers."hourly-services" = {
    #     wantedBy = [ "timers.target" ];
    #     timerConfig = {
    #       OnBootSec = "1h";
    #       OnUnitActiveSec = "1h";
    #       Unit = "hourly-services.service";
    #     };
    #   };

    #   services."hourly-services" = {
    #       script = ''
    #         ${pkgs.sudo}/bin/sudo /etc/openvpn/iptables.sh
    #         ${pkgs.sudo}/bin/sudo -u vpn -i -- ${pkgs.curl}/bin/curl -c /opt/persists/mam.cookies -b /opt/persists/mam.cookies https://t.myanonamouse.net/json/dynamicSeedbox.php
    #       '';
    #       serviceConfig = {
    #         Type = "oneshot";
    #         User = "root";
    #       };
    #     };

    #   timers."reboot-portforward" = {
    #     wantedBy = [ "timers.target" ];
    #     timerConfig = {
    #       OnBootSec = "1m";
    #       Unit = "reboot-portforward.service";
    #     };
    #   };

    #   services."reboot-portforward" = {
    #     script = ''
    #       sleep 60
    #       /etc/openvpn/portforward.sh | while IFS= read -r line; do echo "$(date) $line"; done >> /var/log/pia_portforward.log 2>&1
    #     '';
    #     serviceConfig = {
    #       Type = "oneshot";
    #       User = "root";
    #     };
    #   };

    #   tmpfiles.rules = [
    #     "d /run/openvpn 644 root root 10d"
    #     "f /run/openvpn/openvpn.pid 0644 root root"
    #     "f /run/openvpn/openvpn.status 0644 root root"
    #   ];

    #   services."pia-pf" = {

    #     path = with pkgs; [
    #       toybox
    #       jq
    #       curl
    #       traceroute
    #       bash
    #       gawk
    #       ];
    #     description = "PIA Port Forwarding Daemon";
    #     after = [ "network.target" "openvpn@openvpn.service" ];
    #     wantedBy = [ "multi-user.target" ];
    #     serviceConfig = {
    #       SyslogIdentifier = "pia-pf";
    #       Type = "simple";
    #       ExecStartPre = "${pkgs.toybox}/bin/sleep 10";
    #       ExecStart = "/etc/openvpn/pia-portforward.sh -f tun0 -p /etc/openvpn/port.dat -s /etc/openvpn/portforward.sh";
    #       WorkingDirectory = "/etc/openvpn";
    #       Restart = "always";
    #       RestartSec = 5;
    #       TimeoutStopSec = 30;
    #     };
    #   };
    #   services."openvpn@openvpn" = {

    #     description = "Open VPN connection to %i";
    #     after = [ "network.target" ];
    #     wantedBy = [ "multi-user.target" ];
    #     serviceConfig = {
    #       RuntimeDirectory = "openvpn";
    #       PrivateTmp = true;
    #       KillMode = "mixed";
    #       Type = "forking";
    #       ExecStart = "${pkgs.openvpn}/bin/openvpn --daemon ovpn-%i --status /run/openvpn/%i.status 10 --cd /etc/openvpn --script-security 2 --config /etc/openvpn/%i.conf --writepid /run/openvpn/%i.pid";
    #       PIDFile = "/run/openvpn/%i.pid";
    #       ExecReload = "/bin/kill -HUP $MAINPID";
    #       WorkingDirectory = "/etc/openvpn";
    #       Restart = "on-failure";
    #       RestartSec = 3;
    #       ProtectSystem = "yes";
    #       LimitNPROC = 10;
    #       DeviceAllow = [
    #         "/dev/null rw"
    #         "/dev/net/tun rw"
    #       ];
    #     };
    #   };
    # };

    services = {
      radarr = {
        enable = true;
      };
      readarr = {
        enable = true;
      };
      sonarr = {
        enable = true;
      };
      lidarr = {
        enable = true;
      };
      prowlarr = {
        enable = true;
      };
      # openvpn.servers = {
      #   pia = {
      #     autoStart = false;
      #     updateResolvConf = false;
      #     config = "config ${config.sops.templates.vpn.path}";
      #   };
      # };
      # transmission = {
      #   enable = true;
      #   package =
      #     let
      #       pkgs2_94 = import
      #         (builtins.fetchGit {
      #           name = "transmission-2.94";
      #           url = "https://github.com/NixOS/nixpkgs/";
      #           ref = "refs/heads/nixpkgs-unstable";
      #           rev = "4426104c8c900fbe048c33a0e6f68a006235ac50";
      #         })
      #         { };

      #       transmission2_94 = pkgs2_94.transmission;
      #     in
      #     transmission2_94;
      #   user = "vpn";
      #   credentialsFile = config.sops.templates."transmission-rpc".path;
      #   openPeerPorts = true;
      #   settings = {
      #     alt-speed-down = 6000;
      #     alt-speed-enabled = false;
      #     alt-speed-time-begin = 0;
      #     alt-speed-time-day = 127;
      #     alt-speed-time-enabled = true;
      #     alt-speed-time-end = 360;
      #     alt-speed-up = 1000;
      #     bind-address-ipv4 = "0.0.0.0";
      #     bind-address-ipv6 = "fe80::";
      #     blocklist-enabled = false;
      #     blocklist-url = "http://www.example.com/blocklist";
      #     cache-size-mb = 256;
      #     dht-enabled = false;
      #     download-dir = "/Vault/Eternor/New";
      #     download-limit = 100;
      #     download-limit-enabled = 0;
      #     download-queue-enabled = true;
      #     download-queue-size = 5;
      #     encryption = 2;
      #     idle-seeding-limit = 30;
      #     idle-seeding-limit-enabled = false;
      #     incomplete-dir = "/var/lib/transmission-daemon/Downloads";
      #     incomplete-dir-enabled = false;
      #     lpd-enabled = false;
      #     max-peers-global = 200;
      #     message-level = 1;
      #     peer-congestion-algorithm = "";
      #     peer-id-ttl-hours = 6;
      #     peer-limit-global = 100;
      #     peer-limit-per-torrent = 40;
      #     peer-port = 22371;
      #     peer-port-random-high = 65535;
      #     peer-port-random-low = 49152;
      #     peer-port-random-on-start = false;
      #     peer-socket-tos = "default";
      #     pex-enabled = false;
      #     port-forwarding-enabled = false;
      #     preallocation = 1;
      #     prefetch-enabled = true;
      #     queue-stalled-enabled = true;
      #     queue-stalled-minutes = 30;
      #     ratio-limit = 2;
      #     ratio-limit-enabled = false;
      #     rename-partial-files = true;
      #     rpc-authentication-required = true;
      #     rpc-bind-address = "0.0.0.0";
      #     rpc-enabled = true;
      #     rpc-host-whitelist = "";
      #     rpc-host-whitelist-enabled = true;
      #     rpc-port = 9091;
      #     rpc-url = "/transmission/";
      #     rpc-whitelist = "127.0.0.1,192.168.3.2,192.168.3.3";
      #     rpc-whitelist-enabled = true;
      #     scrape-paused-torrents-enabled = true;
      #     script-torrent-done-enabled = false;
      #     seed-queue-enabled = false;
      #     seed-queue-size = 10;
      #     speed-limit-down = 6000;
      #     speed-limit-down-enabled = true;
      #     speed-limit-up = 500;
      #     speed-limit-up-enabled = true;
      #     start-added-torrents = true;
      #     trash-original-torrent-files = false;
      #     umask = 2;
      #     upload-limit = 100;
      #     upload-limit-enabled = 0;
      #     upload-slots-per-torrent = 14;
      #     utp-enabled = false;
      #   };
      # };

      nginx = {
        virtualHosts = {
          "store.swarsel.win" = {
            enableACME = false;
            forceSSL = false;
            acmeRoot = null;
            locations = {
              "/" = {
                proxyPass = "http://127.0.0.1:9091";
                extraConfig = ''
                  client_max_body_size    0;
                '';
              };
            };
          };
        };
      };
    };
  };
}
