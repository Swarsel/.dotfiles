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

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/sops" ];
    defaultSopsFile = "/.dotfiles/secrets/transmission/secrets.yaml";
    validateSopsFiles = false;
  };

  boot.kernelModules = [ "tun" ];
  proxmoxLXC = {
    manageNetwork = true; # manage network myself
    manageHostName = false; # manage hostname myself
  };
  networking = {
    hostName = "transmission"; # Define your hostname.
    useDHCP = true;
    enableIPv6 = false;
    firewall.enable = false;
  };

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
  };

  networking.iproute2 = {
    enable = true;
    rttablesExtraConfig = ''
                    200     vpn
                    '';
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

  sops = {
    templates = {
      "transmission-rpc" = {
        owner = "vpn";
        content = builtins.toJSON {
          rpc-username = config.sops.placeholder.rpcuser;
          rpc-password = config.sops.placeholder.rpcpass;
        };
      };

      pia.content = ''
                  ${config.sops.placeholder.vpnuser}
                  ${config.sops.placeholder.vpnpass}
                  '';

      vpn.content = ''
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
    };
    secrets = {
      vpnuser = {};
      rpcuser = {owner="vpn";};
      vpnpass = {};
      rpcpass = {owner="vpn";};
      vpnprot = {};
      vpnloc = {};
    };
  };
  services.openvpn.servers = {
    pia = {
      autoStart = false;
      updateResolvConf = true;
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


}
