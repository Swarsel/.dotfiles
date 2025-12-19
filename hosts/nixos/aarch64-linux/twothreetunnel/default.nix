{ self, lib, minimal, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    "${self}/modules/nixos/optional/systemd-networkd-server.nix"
    "${self}/modules/nixos/optional/nix-topology-self.nix"
  ];

  topology.self = {
    icon = "devices.cloud-server";
  };

  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 2 vCPUs, 8GB RAM";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isSwap = false;
    rootDisk = "/dev/disk/by-id/scsi-3608deb9b0d4244de95c6620086ff740d";
    isBtrfs = true;
    isNixos = true;
    isLinux = true;
    isCloud = true;
    server = {
      wireguard = {
        ifName = "wg";
        isServer = true;
        peers = [
          "moonside"
          "winters"
          "belchsfactory"
          "eagleland"
        ];
      };
    };
  };
} // lib.optionalAttrs (!minimal) {
  swarselprofiles = {
    server = true;
  };

  swarselmodules.server = {
    nginx = true; # for now
    oauth2-proxy = true; # for now
    dns-hostrecord = true;
    wireguard = true;
  };

}
