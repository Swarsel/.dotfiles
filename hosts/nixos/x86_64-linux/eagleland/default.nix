{ self, lib, minimal, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    "${self}/modules/nixos/optional/systemd-networkd-server.nix"
    "${self}/modules/nixos/optional/nix-topology-self.nix"
  ] ++ lib.optionals (!minimal) [
    "${self}/profiles/nixos/localserver"
    "${self}/modules/nixos/server/mailserver.nix"
    "${self}/modules/nixos/server/wireguard.nix"
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
    isNixos = true;
    isLinux = true;
    proxyHost = "twothreetunnel"; # mail shall not be proxied through twothreetunnel

  };
} // lib.optionalAttrs (!minimal) {

  networking.nftables.firewall.zones.untrusted.interfaces = [ "wan" ];

}
