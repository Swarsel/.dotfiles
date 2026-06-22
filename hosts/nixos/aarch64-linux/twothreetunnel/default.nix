{
  self,
  config,
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
    self.modules.nixos.nginx
    self.modules.nixos.nginx-exporter
    self.modules.nixos.crowdsec
    self.modules.nixos.acme
    self.modules.nixos.oauth2-proxy
    self.modules.nixos.wireguard
    self.modules.nixos.firezone
    self.modules.nixos.nginx-otel
  ];

  topology.self = {
    icon = "devices.cloud-server";
  };

  globals = {
    wireguard.wgProxy = {
      server = config.node.name;
      netConfigPrefix = config.node.name;
      clients = [
        "moonside"
        "winters"
        "summers"
        "summers-ankisync"
        "summers-atuin"
        "summers-audio"
        "summers-firefly"
        "summers-forgejo"
        "summers-freshrss"
        "summers-homebox"
        "summers-immich"
        "summers-jellyfin"
        "summers-kanidm"
        "summers-kavita"
        "summers-koillection"
        "summers-matrix"
        "summers-mealie"
        "summers-monitoring"
        "summers-nextcloud"
        "summers-paperless"
        "summers-radicale"
        "summers-storage"
        "belchsfactory"
        "eagleland"
        "hintbooth-adguardhome"
      ];
    };
  };

  swarselsystems = {
    nodeRoles = [
      "webProxy"
      "oauthServer"
    ];
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 2 vCPUs, 8GB RAM";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isSwap = false;
    rootDisk = "/dev/disk/by-id/scsi-3608deb9b0d4244de95c6620086ff740d";
    isBtrfs = true;
    isLinux = true;
    isCloud = true;
  };
}
// lib.optionalAttrs (!minimal) {

  networking.nftables = {
    firewall.zones.untrusted.interfaces = [ "lan" ];
    chains.forward.dnat = {
      after = [ "conntrack" ];
      rules = [ "ct status dnat accept" ];
    };
  };

}
