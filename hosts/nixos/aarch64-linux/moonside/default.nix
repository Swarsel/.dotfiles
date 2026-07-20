{
  self,
  config,
  lib,
  minimal,
  ...
}:
let
  inherit (config.repo.secrets.local.syncthing)
    dev1
    dev2
    dev3
    devices
    loc1
    ;
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    self.modules.nixos.systemd-networkd-server
    self.modules.nixos.nix-topology-self
  ]
  ++ lib.optionals (!minimal) [
    self.modules.nixos.profile-localserver
    self.modules.nixos.wireguard
    self.modules.nixos.croc
    self.modules.nixos.microbin
    self.modules.nixos.shlink
    self.modules.nixos.slink
    self.modules.nixos.server-syncthing
    self.modules.nixos.minecraft
    self.modules.nixos.restic
    self.modules.nixos.searx
    self.modules.nixos.invidious
    self.modules.nixos.firefox-syncserver
    self.modules.nixos.copyparty
    self.modules.nixos.shopservatory
  ];
  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 4 vCPUs, 24GB RAM";
    isBtrfs = true;
    isCloud = true;
    isCrypted = false;
    isImpermanence = true;
    isLinux = true;
    isSecureBoot = false;
    isSwap = false;
    nodeRoles = [ "webSyncthingServer" ];
    proxyHost = "twothreetunnel";
    rootDisk = "/dev/sda";
    server.restic.targets.SwarselMoonside = {
      paths = [
        "/persist/opt/minecraft"
      ];
      repository = config.repo.secrets.local.resticRepo;
    };
  };
  globals.services.syncthing-moonside.extraConfig = {
    dataDir = "/sync";
    extraDevices = devices;
    extraFolders = {
      "${loc1}" = {
        devices = [
          dev1
          dev2
          dev3
        ];
        id = "5gsxv-rzzst";
        path = "/sync/${loc1}";
        type = "sendreceive";
        versioning = {
          params.keep = "3";
          type = "simple";
        };
      };
      "Documents" = {
        devices = [ "pyramid" ];
        id = "hgr3d-pfu3w";
        path = "/sync/Documents";
        type = "receiveonly";
        versioning = {
          params.keep = "2";
          type = "simple";
        };
      };
      "runandbun" = {
        devices = [
          "pyramid"
          "magicant"
        ];
        id = "kwnql-ev64v";
        path = "/sync/runandbun";
        type = "receiveonly";
        versioning = {
          params.keep = "5";
          type = "simple";
        };
      };
    };
  };
  system.stateVersion = "23.11";
}
// lib.optionalAttrs (!minimal) {

  networking.nftables.firewall.zones.untrusted.interfaces = [ "lan" ];
}
