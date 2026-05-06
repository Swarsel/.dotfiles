{ self, lib, config, minimal, ... }:
let
  inherit (config.repo.secrets.local.syncthing) dev1 dev2 dev3 loc1 devices;
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    "${self}/modules/nixos/optional/systemd-networkd-server.nix"
    "${self}/modules/nixos/optional/nix-topology-self.nix"
  ] ++ lib.optionals (!minimal) [
    "${self}/profiles/nixos/localserver"
    "${self}/modules/nixos/server/wireguard.nix"
    "${self}/modules/nixos/server/croc.nix"
    "${self}/modules/nixos/server/microbin.nix"
    "${self}/modules/nixos/server/shlink.nix"
    "${self}/modules/nixos/server/slink.nix"
    "${self}/modules/nixos/server/syncthing.nix"
    "${self}/modules/nixos/server/minecraft"
    "${self}/modules/nixos/server/restic.nix"
  ];

  system.stateVersion = "23.11";

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
      restic.targets = {
        SwarselMoonside = {
          repository = config.repo.secrets.local.resticRepo;
          paths = [
            "/persist/opt/minecraft"
          ];
        };
      };
    };
  };

  globals.services.syncthing-moonside.extraConfig = {
    dataDir = "/sync";
    extraDevices = devices;
    extraFolders = {
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
        devices = [ "pyramid" "magicant" ];
        id = "kwnql-ev64v";
      };
      "${loc1}" = {
        path = "/sync/${loc1}";
        type = "sendreceive";
        versioning = {
          type = "simple";
          params.keep = "3";
        };
        devices = [ dev1 dev2 dev3 ];
        id = "5gsxv-rzzst";
      };
    };
  };
} // lib.optionalAttrs (!minimal) {

  networking.nftables.firewall.zones.untrusted.interfaces = [ "lan" ];
}
