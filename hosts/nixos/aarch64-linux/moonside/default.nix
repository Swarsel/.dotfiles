{ lib, config, minimal, ... }:
let
  inherit (config.repo.secrets.local.syncthing) dev1 dev2 dev3 loc1;
  inherit (config.swarselsystems) sopsFile;
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  sops = {
    age.sshKeyPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      wireguard-private-key = { inherit sopsFile; };
      wireguard-home-preshared-key = { inherit sopsFile; };
    };
  };

  boot = {
    loader.systemd-boot.enable = true;
    tmp.cleanOnBoot = true;
  };

  environment = {
    etc."issue".text = "\4";
  };

  topology.self = {
    icon = "devices.cloud-server";
    interfaces.wg = {
      addresses = [ "192.168.3.4" ];
      renderer.hidePhysicalConnections = true;
      virtual = true;
      type = "wireguard";
    };
  };

  networking = {
    domain = "subnet03291956.vcn03291956.oraclevcn.com";
    firewall = {
      allowedTCPPorts = [ 8384 ];
    };
    wireguard = {
      enable = true;
      interfaces = {
        home-vpn = {
          privateKeyFile = config.sops.secrets.wireguard-private-key.path;
          # ips = [ "192.168.3.4/32" ];
          ips = [ "192.168.178.201/24" ];
          peers = [
            {
              # publicKey = "NNGvakADslOTCmN9HJOW/7qiM+oJ3jAlSZGoShg4ZWw=";
              publicKey = "PmeFInoEJcKx+7Kva4dNnjOEnJ8lbudSf1cbdo/tzgw=";
              presharedKeyFile = config.sops.secrets.wireguard-home-preshared-key.path;
              name = "moonside";
              persistentKeepalive = 25;
              # endpoint = "${config.repo.secrets.common.ipv4}:51820";
              endpoint = "${config.repo.secrets.common.wireguardEndpoint}";
              # allowedIPs = [
              #   "192.168.3.0/24"
              #   "192.168.1.0/24"
              # ];
              allowedIPs = [
                "192.168.178.0/24"
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

  services.syncthing = {
    dataDir = lib.mkForce "/sync";
    settings = {
      devices = config.swarselsystems.syncthing.devices // {
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
        "Documents" = {
          path = "/sync/Documents";
          type = "receiveonly";
          versioning = {
            type = "simple";
            params.keep = "2";
          };
          devices = [ "pyramid" ];
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

  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 4 vCPUs, 24GB RAM";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = false;
    isSwap = false;
    rootDisk = "/dev/sda";
    isBtrfs = true;
    isNixos = true;
    isLinux = true;
    proxyHost = "moonside";
    server = {
      inherit (config.repo.secrets.local.networking) localNetwork;
    };
    syncthing = {
      serviceDomain = config.repo.secrets.common.services.domains.syncthing3;
    };
  };
} // lib.optionalAttrs (!minimal) {
  swarselprofiles = {
    server = true;
  };

  swarselmodules.server = {
    oauth2-proxy = true;
    croc = true;
    microbin = true;
    shlink = true;
    slink = true;
    syncthing = true;
    diskEncryption = lib.mkForce false;
  };
}
