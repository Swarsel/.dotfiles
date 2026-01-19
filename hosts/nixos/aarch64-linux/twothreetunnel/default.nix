{ self, config, lib, minimal, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    "${self}/modules/nixos/optional/systemd-networkd-server.nix"
    "${self}/modules/nixos/optional/nix-topology-self.nix"
  ];

  topology.self = {
    icon = "devices.cloud-server";
  };

  globals.general = {
    webProxy = config.node.name;
    oauthServer = config.node.name;
  };

  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 2 vCPUs, 8GB RAM";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isSwap = false;
    rootDisk = "/dev/disk/by-id/scsi-3608deb9b0d4244de95c6620086ff740d";
    isBtrfs = true;
    isNixos = true;
    isLinux = true;
    isCloud = true;
    server = {
      wireguard.interfaces = {
        wgProxy = {
          isServer = true;
          peers = [
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
    };
  };
} // lib.optionalAttrs (!minimal) {
  swarselprofiles = {
    server = true;
  };

  swarselmodules.server = {
    nginx = true;
    oauth2-proxy = true;
    wireguard = true;
    firezone = true;
  };

  networking.nftables = {
    firewall.zones.untrusted.interfaces = [ "lan" ];
    chains.forward.dnat = {
      after = [ "conntrack" ];
      rules = [ "ct status dnat accept" ];
    };
  };

}
