{ config, pkgs, modulesPath, ... }:

            {
              imports = [
                (modulesPath + "/virtualisation/proxmox-lxc.nix")
                ./hardware-configuration.nix
                # ./openvpn.nix #this file holds the vpn login data
              ];

              environment.systemPackages = with pkgs; [
                git
                gnupg
                ssh-to-age
                openvpn
                jq
                iptables
                busybox
                wireguard-tools
              ];

              users.groups.lxc_shares = {
                gid = 10000;
                members = [
                  "vpn"
                  "radarr"
                  "sonarr"
                  "lidarr"
                  "readarr"
                  "root"
                ];
              };
              users.groups.vpn = {};

              users.users.vpn = {
                isNormalUser = true;
                group = "vpn";
                home = "/home/vpn";
              };

              services.xserver = {
                layout = "us";
                xkbVariant = "altgr-intl";
              };

              nix.settings.experimental-features = ["nix-command" "flakes"];

              sops.age.sshKeyPaths = [ "/etc/ssh/sops" ];
              sops.defaultSopsFile = "/.dotfiles/secrets/transmission/secrets.yaml";
              sops.validateSopsFiles = false;

              boot.kernelModules = [ "tun" ];
              proxmoxLXC.manageNetwork = true; # manage network myself
              proxmoxLXC.manageHostName = false; # manage hostname myself
              networking.hostName = "transmission"; # Define your hostname.
              networking.useDHCP = true;
              networking.enableIPv6 = false;
              networking.firewall.enable = false;

              services.radarr = {
                enable = true;
              };

              services.readarr = {
                enable = true;
              };
              services.sonarr = {
                enable = true;
              };
              services.lidarr = {
                enable = true;
              };
              services.prowlarr = {
                enable = true;
              };

              # networking.interfaces = {
                  # lo = {
                    # useDHCP = false;
                    # ipv4.addresses = [
                      # { address = "127.0.0.1"; prefixLength = 8; }
                    # ];
                  # };
              #
                  # eth0 = {
                    # useDHCP = true;
                  # };
                # };

              # networking.firewall.extraCommands = ''
              # sudo iptables -A OUTPUT ! -o lo -m owner --uid-owner vpn -j DROP
              # '';
              networking.iproute2 = {
                enable = true;
                rttablesExtraConfig = ''
                200     vpn
                '';
              };
              # boot.kernel.sysctl = {
              #   "net.ipv4.conf.all.rp_filter" = 2;
              #   "net.ipv4.conf.default.rp_filter" = 2;
              #   "net.ipv4.conf.eth0.rp_filter" = 2;
              # };
              environment.etc = {
                "openvpn/iptables.sh" =
                  { source = ../../../scripts/server1/iptables.sh;
                    mode = "0755";
                  };
                "openvpn/update-resolv-conf" =
                  { source = ../../../scripts/server1/update-resolv-conf;
                    mode = "0755";
                  };
                "openvpn/routing.sh" =
                  { source = ../../../scripts/server1/routing.sh;
                    mode = "0755";
                  };
                "openvpn/ca.rsa.2048.crt" =
                  { source = ../../../secrets/certs/ca.rsa.2048.crt;
                    mode = "0644";
                  };
                "openvpn/crl.rsa.2048.pem" =
                  { source = ../../../secrets/certs/crl.rsa.2048.pem;
                    mode = "0644";
                  };
              };
              services.openssh = {
                enable = true;
                settings.PermitRootLogin = "yes";
                listenAddresses = [{
                                   port = 22;
                                   addr = "0.0.0.0";
                                 }];
              };
              users.users.root.openssh.authorizedKeys.keyFiles = [
                ../../../secrets/keys/authorized_keys
              ];

              system.stateVersion = "23.05"; # TEMPLATE - but probably no need to change
              # users.users.root.password = "TEMPLATE";

              environment.shellAliases = {
                nswitch = "cd /.dotfiles; git pull; nixos-rebuild --flake .#$(hostname) switch; cd -;";
              };

              sops.secrets.vpnuser = {};
              sops.secrets.rpcuser = {owner="vpn";};
              sops.secrets.vpnpass = {};
              sops.secrets.rpcpass = {owner="vpn";};
              sops.secrets.vpnprot = {};
              sops.secrets.vpnloc = {};
              # sops.secrets.crlpem = {};
              # sops.secrets.capem = {};
              sops.templates."transmission-rpc".owner = "vpn";
              sops.templates."transmission-rpc".content = builtins.toJSON {
                rpc-username = config.sops.placeholder.rpcuser;
                rpc-password = config.sops.placeholder.rpcpass;
              };

              sops.templates.pia.content = ''
              ${config.sops.placeholder.vpnuser}
              ${config.sops.placeholder.vpnpass}
              '';

              sops.templates.vpn.content = ''
                client
                dev tun
                proto ${config.sops.placeholder.vpnprot}
                remote ${config.sops.placeholder.vpnloc}
                resolv-retry infinite
                nobind
                persist-key
                persist-tun
                cipher aes-128-cbc
                auth sha1
                tls-client
                remote-cert-tls server

                auth-user-pass ${config.sops.templates.pia.path}
                compress
                verb 1
                reneg-sec 0

                crl-verify /etc/openvpn/crl.rsa.2048.pem
                ca /etc/openvpn/ca.rsa.2048.crt

                disable-occ
                dhcp-option DNS 209.222.18.222
                dhcp-option DNS 209.222.18.218
                dhcp-option DNS 8.8.8.8
                route-noexec
              '';

              # services.pia.enable = true;
              # services.pia.authUserPass.username = "na";
              # services.pia.authUserPass.password = "na";


            #     systemd.services.openvpn-vpn = {
            # wantedBy = [ "multi-user.target" ];
            # after = [ "network.target" ];
            # description = "OpenVPN connection to pia";
            # serviceConfig = {
            #   Type = "forking";
            #   RuntimeDirectory="openvpn";
            #   PrivateTmp=true;
            #   KillMode="mixed";
            #   ExecStart = ''@${pkgs.openvpn}/sbin/openvpn openvpn --daemon ovpn-pia --status /run/openvpn/pia.status 10 --cd /etc/openvpn --script-security 2 --config ${config.sops.templates.vpn.path} --writepid /run/openvpn/pia.pid'';
            #   PIDFile=''/run/openvpn/pia.pid'';
            #   ExecReload=''/run/current-system/sw/bin/kill -HUP $MAINPID'';
            #   WorkingDirectory="/etc/openvpn";
            #   Restart="on-failure";
            #   RestartSec=30;
            #   ProtectSystem="yes";
            #   DeviceAllow=["/dev/null rw" "/dev/net/tun rw"];
            # };
         # };
          services.openvpn.servers = {
            pia = {
              autoStart = false;
              updateResolvConf = true;
#               up = ''
# export INTERFACE="tun0"
# export VPNUSER="vpn"
# export LOCALIP="192.168.1.191"
# export NETIF="eth0"
# export VPNIF="tun0"
# export GATEWAYIP=$(ifconfig $VPNIF | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}' | egrep -v '255|(127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})' | tail -n1)
# iptables -F -t nat
# iptables -F -t mangle
# iptables -F -t filter
# iptables -t mangle -A OUTPUT -j CONNMARK --restore-mark
# iptables -t mangle -A OUTPUT ! --dest $LOCALIP -m owner --uid-owner $VPNUSER -j MARK --set-mark 0x1
# iptables -t mangle -A OUTPUT --dest $LOCALIP -p udp --dport 53 -m owner --uid-owner $VPNUSER -j MARK --set-mark 0x1
# iptables -t mangle -A OUTPUT --dest $LOCALIP -p tcp --dport 53 -m owner --uid-owner $VPNUSER -j MARK --set-mark 0x1
# iptables -t mangle -A OUTPUT ! --src $LOCALIP -j MARK --set-mark 0x1
# iptables -t mangle -A OUTPUT -j CONNMARK --save-mark
# iptables -A INPUT -i $INTERFACE -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# iptables -A INPUT -i $INTERFACE -j REJECT
# iptables -A OUTPUT -o lo -m owner --uid-owner $VPNUSER -j ACCEPT
# iptables -A OUTPUT -o $INTERFACE -m owner --uid-owner $VPNUSER -j ACCEPT
# iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE
# iptables -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# iptables -A OUTPUT ! --src $LOCALIP -o $NETIF -j REJECT
# if [[ `ip rule list | grep -c 0x1` == 0 ]]; then
# ip rule add from all fwmark 0x1 lookup $VPNUSER
# fi
# ip route replace default via $GATEWAYIP table $VPNUSER
# ip route append default via 127.0.0.1 dev lo table $VPNUSER
# ip route flush cache
              # '';
              # down = "bash /etc/openvpn/update-resolv-conf";
              # these are outsourced to a local file, I am not sure if it can be done with sops-nix
              # authUserPass = {
                # username = "TODO:secrets";
                # password = "TODO:secrets";
              # };
              config = "config ${config.sops.templates.vpn.path}";
            };
          };

        services.transmission = {
          enable = true;
          credentialsFile = config.sops.templates."transmission-rpc".path;
          user = "vpn";
          group = "lxc_shares";
          settings = {

          alt-speed-down= 8000;
          alt-speed-enabled= false;
          alt-speed-time-begin= 0;
          alt-speed-time-day= 127;
          alt-speed-time-enabled= true;
          alt-speed-time-end= 360;
          alt-speed-up= 2000;
          bind-address-ipv4= "0.0.0.0";
          bind-address-ipv6= "::";
          blocklist-enabled= false;
          blocklist-url= "http://www.example.com/blocklist";
          cache-size-mb= 4;
          dht-enabled= false;
          download-dir= "/media/Eternor/New";
          download-limit= 100;
          download-limit-enabled= 0;
          download-queue-enabled= true;
          download-queue-size= 5;
          encryption= 2;
          idle-seeding-limit= 30;
          idle-seeding-limit-enabled= false;
          incomplete-dir= "/var/lib/transmission-daemon/Downloads";
          incomplete-dir-enabled= false;
          lpd-enabled= false;
          max-peers-global= 200;
          message-level= 1;
          peer-congestion-algorithm= "";
          peer-id-ttl-hours= 6;
          peer-limit-global= 100;
          peer-limit-per-torrent= 40;
          peer-port= 22371;
          peer-port-random-high= 65535;
          peer-port-random-low= 49152;
          peer-port-random-on-start= false;
          peer-socket-tos= "default";
          pex-enabled= false;
          port-forwarding-enabled= false;
          preallocation= 1;
          prefetch-enabled= true;
          queue-stalled-enabled= true;
          queue-stalled-minutes= 30;
          ratio-limit= 2;
          ratio-limit-enabled= false;
          rename-partial-files= true;
          rpc-authentication-required= true;
          rpc-bind-address= "0.0.0.0";
          rpc-enabled= true;
          rpc-host-whitelist= "";
          rpc-host-whitelist-enabled= true;
          rpc-port= 9091;
          rpc-url= "/transmission/";
          rpc-whitelist= "127.0.0.1,192.168.3.2";
          rpc-whitelist-enabled= true;
          scrape-paused-torrents-enabled= true;
          script-torrent-done-enabled= false;
          seed-queue-enabled= false;
          seed-queue-size= 10;
          speed-limit-down= 6000;
          speed-limit-down-enabled= true;
          speed-limit-up= 500;
          speed-limit-up-enabled= true;
          start-added-torrents= true;
          trash-original-torrent-files= false;
          umask= 2;
          upload-limit= 100;
          upload-limit-enabled= 0;
          upload-slots-per-torrent= 14;
          utp-enabled= false;
          };
        };

      # services.nginx = {
      #       enable = true;
      #       virtualHosts = {

      #         "192.168.1.192" = {
      #           locations = {
      #             "/transmission" = {
      #               proxyPass = "http://127.0.0.1:9091";
      #               extraConfig = ''
      #               proxy_set_header Host $host;
      #               proxy_set_header X-Real-IP $remote_addr;
      #               proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      #               '';
      #             };
      #           };
      #         };
      #       };
      # };


            }
