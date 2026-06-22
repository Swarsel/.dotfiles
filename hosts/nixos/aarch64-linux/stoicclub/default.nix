{
  self,
  lib,
  minimal,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    self.modules.nixos.systemd-networkd-server
    self.modules.nixos.nix-topology-self
  ]
  ++ lib.optionals (!minimal) [
    self.modules.nixos.profile-localserver
    self.modules.nixos.nsd
  ];

  topology.self = {
    icon = "devices.cloud-server";
  };

  swarselsystems = {
    nodeRoles = [ "dnsServer" ];
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 1 vCPUs, 8GB RAM";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isSwap = false;
    rootDisk = "/dev/disk/by-id/scsi-360e1a5236f034316a10a97cc703ce9e3";
    isBtrfs = true;
    isLinux = true;
    isCloud = true;
    isBastionTarget = true;
  };

}
// lib.optionalAttrs (!minimal) {

  networking.nftables.firewall.zones.untrusted.interfaces = [ "lan" ];
}
