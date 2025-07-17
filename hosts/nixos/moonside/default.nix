{ lib, config, globals, ... }:
let
  inherit (config.repo.secrets.common) workHostName;
  inherit (config.repo.secrets.local.syncthing) dev1 dev2 dev3 loc1;
  inherit (config.swarselsystems) sopsFile;
  serviceDomain = config.repo.secrets.common.services.domains.syncthing3;
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  sops = {
    age.sshKeyPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];
    # defaultSopsFile = lib.mkForce "/home/swarsel/.dotfiles/secrets/moonside/secrets.yaml";
    secrets = {
      wireguard-private-key = { inherit sopsFile; };
    };
  };

  boot = {
    loader.systemd-boot.enable = true;
    tmp.cleanOnBoot = true;
  };

  environment = {
    etc."issue".text = "\4";

    persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      {
        directory = "/var/lib/syncthing";
        user = "syncthing";
        group = "syncthing";
        mode = "0700";
      }
    ];
  };

  topology.self.interfaces.wg = {
    addresses = [ "192.168.3.4" ];
    renderer.hidePhysicalConnections = true;
    virtual = true;
    type = "wireguard";
  };

  networking = {
    nftables.enable = lib.mkForce false;
    hostName = "moonside";
    enableIPv6 = false;
    domain = "subnet03291956.vcn03291956.oraclevcn.com";
    firewall = {
      allowedTCPPorts = [ 80 443 8384 ];
    };
    wireguard = {
      enable = true;
      interfaces = {
        home-vpn = {
          privateKeyFile = config.sops.secrets.wireguard-private-key.path;
          ips = [ "192.168.3.4/32" ];
          peers = [
            {
              publicKey = "NNGvakADslOTCmN9HJOW/7qiM+oJ3jAlSZGoShg4ZWw=";
              name = "moonside";
              persistentKeepalive = 25;
              endpoint = "${config.repo.secrets.common.ipv4}:51820";
              allowedIPs = [
                "192.168.3.0/24"
                "192.168.1.0/24"
              ];
            }
          ];
        };
      };
    };
  };

  hardware = {
    enableAllFirmware = lib.mkForce false;
  };

  system.stateVersion = "23.11";

  globals.services."syncthing-${config.networking.hostName}".domain = serviceDomain;

  services = {
    nginx = {
      virtualHosts = {
        ${serviceDomain} = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://localhost:8384";
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
            path = "/sync/Sync";
            type = "receiveonly";
            versioning = null;
            devices = [ "winters" "magicant" "${workHostName}" ];
            id = "default";
          };
          "Obsidian" = {
            path = "/sync/Obsidian";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = [ "winters" "magicant" "${workHostName}" ];
            id = "yjvni-9eaa7";
          };
          "Org" = {
            path = "/sync/Org";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = [ "winters" "magicant" "${workHostName}" ];
            id = "a7xnl-zjj3d";
          };
          "Vpn" = {
            path = "/sync/Vpn";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = [ "winters" "magicant" "${workHostName}" ];
            id = "hgp9s-fyq3p";
          };
          "Documents" = {
            path = "/sync/Documents";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "2";
            };
            devices = [ "winters" ];
            id = "hgr3d-pfu3w";
          };
          "runandbun" = {
            path = "/sync/runandbun";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = [ "winters" "magicant" ];
            id = "kwnql-ev64v";
          };
          "${loc1}" = {
            path = "/sync/${loc1}";
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

  swarselprofiles = {
    server.moonside = true;
  };

  swarselsystems = {
    info = "VM.Standard.A1.Flex, 4 OCPUs, 24GB RAM";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = false;
    isSwap = false;
    rootDisk = "/dev/sda";
    isBtrfs = true;
    isNixos = true;
    isLinux = true;
  };
}
