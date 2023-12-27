{ config, pkgs, modulesPath, ... }:

    {
      imports = [
        (modulesPath + "/virtualisation/proxmox-lxc.nix")
        ./hardware-configuration.nix
        ./openvpn.nix
      ];

      environment.systemPackages = with pkgs; [
        git
        gnupg
        ssh-to-age
        openvpn
      ];

      users.groups.lxc_shares = {
        gid = 10000;
        members = [
          "transmission"
          "root"
        ];
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
      sops.templates."rpc.json".owner = "transmission";
      sops.templates."rpc.json".content = ''
      "rpc-password": "${config.sops.placeholder.rpcpass}",
      "rpc-username": "${config.sops.placeholder.rpcuser}",
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

        auth-user-pass
        compress
        verb 1
        reneg-sec 0

        <crl-verify>
        -----BEGIN X509 CRL-----
        ${config.sops.placeholder.crlpem}
        -----END X509 CRL-----
        </crl-verify>

        <ca>
        -----BEGIN CERTIFICATE-----
        ${config.sops.placeholder.capem}
        -----END CERTIFICATE-----
        </ca>

        disable-occ
      '';
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
  # credentialsFile = config.sops.templates."rpc.json".path;
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
  download-dir= "/home/htpcguides/Download";
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
  rpc-whitelist= "127.0.0.1";
  rpc-whitelist-enabled= true;
  scrape-paused-torrents-enabled= true;
  script-torrent-done-enabled= false;
  script-torrent-done-filename= "";
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
