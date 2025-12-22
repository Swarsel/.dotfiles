{ self, lib, config, minimal, ... }:
let
  inherit (config.repo.secrets.local.syncthing) dev1 dev2 dev3 loc1;
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    "${self}/modules/nixos/optional/systemd-networkd-server.nix"
    "${self}/modules/nixos/optional/nix-topology-self.nix"
  ];

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
    isCloud = true;
    proxyHost = "twothreetunnel";
    server = {
      wireguard.interfaces = {
        wgProxy = {
          isClient = true;
          serverName = "twothreetunnel";
        };
      };
      restic = {
        bucketName = "SwarselMoonside";
        paths = [
          "/persist/opt/minecraft"
        ];
      };
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
    wireguard = true;
    croc = true;
    microbin = true;
    shlink = true;
    slink = true;
    syncthing = true;
    minecraft = true;
    restic = true;
    diskEncryption = lib.mkForce false;
    dns-hostrecord = true;
  };
}
