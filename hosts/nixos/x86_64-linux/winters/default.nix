{
  self,
  lib,
  globals,
  minimal,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix

    self.modules.nixos.systemd-networkd-server
    self.modules.nixos.nix-topology-self
  ]
  ++ lib.optionals (!minimal) [
    self.modules.nixos.profile-localserver
    self.modules.nixos.smartctl-exporter
  ];
  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "ASRock J4105-ITX, 32GB RAM";
    isBtrfs = false;
    isCrypted = false;
    isImpermanence = false;
    isLinux = true;
    isSecureBoot = false;
    proxyHost = "twothreetunnel";

  };
  topology.self.interfaces."eth1" = { };
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };
  networking.hosts = {
    ${globals.networks.home-lan.hosts.hintbooth.ipv4} = [ "server.hintbooth.${globals.domains.main}" ];
    ${globals.networks.home-lan.hosts.hintbooth.ipv6} = [ "server.hintbooth.${globals.domains.main}" ];
  };

}
// lib.optionalAttrs (!minimal) {

  networking.nftables.firewall.zones.untrusted.interfaces = [
    "lan"
    "enp3s0"
  ];

}
