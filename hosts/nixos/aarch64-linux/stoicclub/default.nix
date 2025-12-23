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
    info = "VM.Standard.A1.Flex, 1 vCPUs, 8GB RAM";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isSwap = false;
    rootDisk = "/dev/disk/by-id/scsi-360e1a5236f034316a10a97cc703ce9e3";
    isBtrfs = true;
    isNixos = true;
    isLinux = true;
    isCloud = true;
    isBastionTarget = true;
  };
} // lib.optionalAttrs (!minimal) {
  swarselprofiles = {
    server = true;
  };

  swarselmodules.server = {
    nsd = true;
    dns-hostrecord = true;
  };
}
