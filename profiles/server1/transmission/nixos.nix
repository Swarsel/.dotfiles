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
        iptables
      ];

      users.groups.lxc_shares = {
        gid = 10000;
        members = [
          "transmission"
          "vpn"
          "root"
        ];
      };

      users.users.vpn = {
        isNormalUser = true;
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
      networking.firewall.extraCommands = ''
      sudo iptables -A OUTPUT ! -o lo -m owner --uid-owner vpn -j DROP
      '';
      networking.iproute2 = {
        enable = true;
        rttablesExtraConfig = ''
        200     vpn
        '';
      };
      boot.kernel.sysctl = {
        "net.ipv4.conf.all.rp_filter" = 2;
        "net.ipv4.conf.default.rp_filter" = 2;
        "net.ipv4.conf.eth0.rp_filter" = 2;
      };
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
      sops.secrets.rpcuser = {owner="transmission";};
      sops.secrets.vpnpass = {};
      sops.secrets.rpcpass = {owner="transmission";};
      sops.secrets.vpnprot = {};
      sops.secrets.vpnloc = {};
      sops.secrets.crlpem = {};
      sops.secrets.capem = {};
      sops.templates."transmission-rpc".owner = "transmission";
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
        auth-nocache
        comp-lzo
        verb 1
        reneg-sec 0

        crl-verify /etc/openvpn/crl.rsa.2048.pem
        ca /etc/openvpn/ca.rsa.2048.crt

        disable-occ
        script-security 2
        route-noexec
        up /etc/openvpn/iptables.sh
        down /etc/openvpn/update-resolv-conf
      '';

        systemd.services.openvpn-vpn = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    description = "OpenVPN connection to %i";
    serviceConfig = {
      Type = "forking";
      RuntimeDirectory="openvpn";
      PrivateTmp=true;
      KillMode="mixed";
      ExecStart = ''${pkgs.openvpn}/bin/openvpn --daemon ovpn-%i --status /run/openvpn/%i.status 10 --cd /etc/openvpn --script-security 2 --config ${config.sops.templates.vpn.path} --writepid /run/openvpn/%i.pid'';
      PIDFile=''/run/openvpn/%i.pid'';
      ExecReload=''/run/current-system/sw/bin/kill -HUP $MAINPID'';
      WorkingDirectory="/etc/openvpn";
      Restart="on-failure";
      RestartSec=3;
      ProtectSystem="yes";
      LimitNPROC=10;
      DeviceAllow=["/dev/null rw" "/dev/net/tun rw"];
    };
 };
  services.openvpn.servers = {
    pia = {
      autoStart = false;
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
  download-dir= "/media/New";
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


    }
