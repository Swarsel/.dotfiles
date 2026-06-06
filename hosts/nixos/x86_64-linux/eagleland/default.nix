{ self, lib, minimal, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    self.modules.nixos.systemd-networkd-server
    self.modules.nixos.nix-topology-self
  ] ++ lib.optionals (!minimal) [
    self.modules.nixos.profile-localserver
    self.modules.nixos.mailserver
    self.modules.nixos.wireguard
  ];

  topology.self = {
    icon = "devices.cloud-server";
  };

  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "2vCPU, 4GB Ram";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isCloud = true;
    isSwap = true;
    swapSize = "4G";
    rootDisk = "/dev/sda";
    isBtrfs = true;
    isLinux = true;
    proxyHost = "twothreetunnel"; # mail shall not be proxied through twothreetunnel

  };
} // lib.optionalAttrs (!minimal) {

  networking.nftables.firewall.zones.untrusted.interfaces = [ "wan" ];

}
