{ self, lib, minimal, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    "${self}/modules/nixos/optional/systemd-networkd-server.nix"
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
  };
} // lib.optionalAttrs (!minimal) {
  swarselprofiles = {
    server = true;
  };

  swarselmodules.server = {
    nginx = false;
    dns-hostrecord = true;
  };

}
