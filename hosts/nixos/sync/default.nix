{ lib, primaryUser, inputs, ... }:
let
  sharedOptions = {
    isBtrfs = false;
    isLinux = true;
  };
  secretsDirectory = builtins.toString inputs.nix-secrets;
  workHostName = lib.swarselsystems.getSecret "${secretsDirectory}/work/worklaptop-hostname";
  dev1 = lib.swarselsystems.getSecret "${secretsDirectory}/oci/sync/syncthing/dev1";
  dev2 = lib.swarselsystems.getSecret "${secretsDirectory}/oci/sync/syncthing/dev2";
  dev3 = lib.swarselsystems.getSecret "${secretsDirectory}/oci/sync/syncthing/dev3";
  loc1 = lib.swarselsystems.getSecret "${secretsDirectory}/oci/sync/syncthing/loc1";
in
{
  imports = [
    ./hardware-configuration.nix
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
      allowedTCPPorts = [ 80 443 8384 9812 22000 27701 ];
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

  hardware = {
    enableAllFirmware = lib.mkForce false;
  };

  system.stateVersion = "23.11";

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

    syncthing = {
      enable = true;
      guiAddress = "0.0.0.0:8384";
      openDefaultPorts = true;
      relay.enable = false;
      settings = {
        urAccepted = -1;
        devices = {
          "magicant" = {
            id = "VMWGEE2-4HDS2QO-KNQOVGN-LXLX6LA-666E4EK-ZBRYRRO-XFEX6FB-6E3XLQO";
          };
          "winters" = {
            id = "O7RWDMD-AEAHPP7-7TAVLKZ-BSWNBTU-2VA44MS-EYGUNBB-SLHKB3C-ZSLMOAA";
          };
          "${workHostName}" = {
            id = "YAPV4BV-I26WPTN-SIP32MV-SQP5TBZ-3CHMTCI-Z3D6EP2-MNDQGLP-53FT3AB";
          };
          "${dev1}" = {
            id = "OCCDGDF-IPZ6HHQ-5SSLQ3L-MSSL5ZW-IX5JTAM-PW4PYEK-BRNMJ7E-Q7YDMA7";
          };
          "${dev2}" = {
            id = "LPCFIIB-ENUM2V6-F2BWVZ6-F2HXCL2-BSBZXUF-TIMNKYB-7CATP7H-YU5D3AH";
          };
          "${dev3}" = {
            id = "LAUT2ZP-KEZY35H-AHR3ARD-URAREJI-2B22P5T-PIMUNWW-PQRDETU-7KIGNQR";
          };
        };
        folders = {
          "Default Folder" = lib.mkForce {
            path = "/var/lib/syncthing/Sync";
            type = "receiveonly";
            versioning = null;
            devices = [ "winters" "magicant" "${workHostName}" ];
            id = "default";
          };
          "Obsidian" = {
            path = "/var/lib/syncthing/Obsidian";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = [ "winters" "magicant" "${workHostName}" ];
            id = "yjvni-9eaa7";
          };
          "Org" = {
            path = "/var/lib/syncthing/Org";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = [ "winters" "magicant" "${workHostName}" ];
            id = "a7xnl-zjj3d";
          };
          "Vpn" = {
            path = "/var/lib/syncthing/Vpn";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = [ "winters" "magicant" "${workHostName}" ];
            id = "hgp9s-fyq3p";
          };
          "${loc1}" = {
            path = "/var/lib/syncthing/${loc1}";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "3";
            };
            devices = [ dev1 dev2 dev3 ];
            id = "5gsxv-rzzst";
          };
        };
      };
    };
  };

  swarselsystems = lib.recursiveUpdate
    {
      flakePath = "/root/.dotfiles";
      isImpermanence = false;
      isSecureBoot = false;
      isCrypted = false;
      profiles = {
        server.sync = true;
      };
    }
    sharedOptions;

  home-manager.users."${primaryUser}" = {
    home.stateVersion = lib.mkForce "23.05";
    swarselsystems = lib.recursiveUpdate
      { }
      sharedOptions;
  };

}
