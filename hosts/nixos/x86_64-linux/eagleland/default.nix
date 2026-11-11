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
    self.modules.nixos.disk-single-root

    self.modules.nixos.systemd-networkd-server
    self.modules.nixos.nix-topology-self
  ]
  ++ lib.optionals (!minimal) [
    self.modules.nixos.profile-localserver
    self.modules.nixos.mailserver
    self.modules.nixos.wireguard
    self.modules.nixos.restic
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
    proxyHost = "twothreetunnel"; # proxies roundcube and mta-sts, mail records point at this host directly
    rootDisk = "/dev/sda";
    server.restic.targets.SwarselMail = {
      paths = [
        "/var/dkim"
        "/var/sieve"
        "/var/vmail"
      ];
      repository = config.repo.secrets.local.resticRepo;
      withPostgres = true;
    };
    swapSize = "4G";

  };
  topology.self.icon = "devices.cloud-server";
}
// lib.optionalAttrs (!minimal) {

  networking.nftables.firewall.zones.untrusted.interfaces = [ "wan" ];

}
