{ self, inputs, lib, primaryUser, ... }:
let
  profilesPath = "${self}/profiles";
in
{
  imports = [

    "${profilesPath}/nixos/server"
    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users."${primaryUser}".imports = [
        "${profilesPath}/home/server"
      ];
    }
  ];

  sops = {
    defaultSopsFile = lib.mkForce "/root/.dotfiles/secrets/sync/secrets.yaml";
  };

  boot = {
    tmp.cleanOnBoot = true;
    loader.grub.device = "nodev";
  };
  zramSwap.enable = false;

  networking = {
    nftables.enable = lib.mkForce false;
    hostName = "sync";
    enableIPv6 = false;
    domain = "subnet03112148.vcn03112148.oraclevcn.com";
    firewall = {
      allowedTCPPorts = [ 8384 22000 ];
      allowedUDPPorts = [ 21027 22000 ];
      extraCommands = ''
        iptables -I INPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT
        iptables -I INPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT
        iptables -I INPUT -m state --state NEW -p tcp --dport 27701 -j ACCEPT
        iptables -I INPUT -m state --state NEW -p tcp --dport 8384 -j ACCEPT
        iptables -I INPUT -m state --state NEW -p tcp --dport 3000 -j ACCEPT
        iptables -I INPUT -m state --state NEW -p tcp --dport 22000 -j ACCEPT
        iptables -I INPUT -m state --state NEW -p udp --dport 22000 -j ACCEPT
        iptables -I INPUT -m state --state NEW -p udp --dport 21027 -j ACCEPT
        iptables -I INPUT -m state --state NEW -p tcp --dport 9812 -j ACCEPT
      '';
    };
  };

  # system.stateVersion = "23.11"; # TEMPLATE - but probably no need to change

  services = {
    nginx = {
      virtualHosts = {
        "sync.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://localhost:8384/";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };
      };
    };

    # do not manage OCI syncthing through nix config
    syncthing = {
      enable = true;
      guiAddress = "0.0.0.0:8384";
      openDefaultPorts = true;
    };
  };


  swarselsystems = {
    hasBluetooth = false;
    hasFingerprint = false;
    isImpermanence = false;
    isLinux = true;
    isBtrfs = false;
    flakePath = "/root/.dotfiles";
    server = {
      enable = true;
      forgejo = true;
      ankisync = true;
    };
  };

}
