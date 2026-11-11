{
  self,
  config,
  lib,
  minimal,
  nodes,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    self.modules.nixos.disk-single-root

    self.modules.nixos.systemd-networkd-server
    self.modules.nixos.nix-topology-self
  ]
  ++ lib.optionals (!minimal) [
    self.modules.nixos.profile-localserver
    self.modules.nixos.nginx
    self.modules.nixos.nginx-exporter
    self.modules.nixos.crowdsec
    self.modules.nixos.acme
    self.modules.nixos.oauth2-proxy
    self.modules.nixos.wireguard
    self.modules.nixos.firezone
    self.modules.nixos.nginx-otel
  ];
  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 2 vCPUs, 8GB RAM";
    isBtrfs = true;
    isCloud = true;
    isCrypted = true;
    isImpermanence = true;
    isLinux = true;
    isSecureBoot = false;
    isSwap = false;
    nodeRoles = [
      "webProxy"
      "oauthServer"
    ];
    rootDisk = "/dev/disk/by-id/scsi-3608deb9b0d4244de95c6620086ff740d";
  };
  topology.self.icon = "devices.cloud-server";
  globals.wireguard.wgProxy = {
    clients = [
      "moonside"
      "stoicclub"
      "winters"
      "summers"
    ]
    ++ builtins.filter (name: nodes.${name}.config.swarselsystems.proxyHost == config.node.name) (
      map (guest: "summers-${guest}") (builtins.attrNames nodes.summers.config.guests)
    )
    ++ [
      "belchsfactory"
      "eagleland"
      "hintbooth-adguardhome"
      "hintbooth-nginx"
    ];
    netConfigPrefix = config.node.name;
    server = config.node.name;
  };
}
// lib.optionalAttrs (!minimal) {

  networking.nftables = {
    chains.forward.dnat = {
      after = [ "conntrack" ];
      rules = [ "ct status dnat accept" ];
    };
    firewall.zones.untrusted.interfaces = [ "lan" ];
  };

}
