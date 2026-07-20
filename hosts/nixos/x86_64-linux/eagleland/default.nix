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
    self.modules.nixos.mailserver
    self.modules.nixos.wireguard
  ];
  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "2vCPU, 4GB Ram";
    isBtrfs = true;
    isCloud = true;
    isCrypted = true;
    isImpermanence = true;
    isLinux = true;
    isSecureBoot = false;
    isSwap = true;
    proxyHost = "twothreetunnel"; # mail shall not be proxied through twothreetunnel
    rootDisk = "/dev/sda";
    swapSize = "4G";

  };
  topology.self.icon = "devices.cloud-server";
}
// lib.optionalAttrs (!minimal) {

  networking.nftables.firewall.zones.untrusted.interfaces = [ "wan" ];

}
