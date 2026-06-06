{ self, lib, minimal, globals, ... }:
{

  imports = [
    ./hardware-configuration.nix

    self.modules.nixos.systemd-networkd-server
    self.modules.nixos.nix-topology-self
  ] ++ lib.optionals (!minimal) [
    self.modules.nixos.profile-localserver
    self.modules.nixos.smartctl-exporter
  ];

  topology.self.interfaces."eth1" = { };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  networking.hosts = {
    ${globals.networks.home-lan.hosts.hintbooth.ipv4} = [ "server.hintbooth.${globals.domains.main}" ];
    ${globals.networks.home-lan.hosts.hintbooth.ipv6} = [ "server.hintbooth.${globals.domains.main}" ];
  };

  swarselsystems = {
    info = "ASRock J4105-ITX, 32GB RAM";
    flakePath = "/root/.dotfiles";
    isImpermanence = false;
    isSecureBoot = false;
    isCrypted = false;
    isBtrfs = false;
    isLinux = true;
    proxyHost = "twothreetunnel";

  };

} // lib.optionalAttrs (!minimal) {

  networking.nftables.firewall.zones.untrusted.interfaces = [ "lan" "enp3s0" ];

}
