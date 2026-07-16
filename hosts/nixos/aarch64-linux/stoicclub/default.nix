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
  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 1 vCPUs, 8GB RAM";
    isBastionTarget = true;
    isBtrfs = true;
    isCloud = true;
    isCrypted = true;
    isImpermanence = true;
    isLinux = true;
    isSecureBoot = false;
    isSwap = false;
    nodeRoles = [ "dnsServer" ];
    rootDisk = "/dev/disk/by-id/scsi-360e1a5236f034316a10a97cc703ce9e3";
  };
  topology.self = {
    icon = "devices.cloud-server";
  };

}
// lib.optionalAttrs (!minimal) {

  networking.nftables.firewall.zones.untrusted.interfaces = [ "lan" ];
}
