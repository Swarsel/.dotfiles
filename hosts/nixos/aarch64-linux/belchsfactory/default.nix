{ self, lib, minimal, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    "${self}/modules/nixos/optional/systemd-networkd-server.nix"
    "${self}/modules/nixos/optional/nix-topology-self.nix"
  ];

  node.lockFromBootstrapping = lib.mkForce false;

  topology.self = {
    icon = "devices.cloud-server";
  };
  swarselmodules.server.nginx = false;

  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 4 vCPUs, 24GB RAM";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isSwap = false;
    rootDisk = "/dev/sda";
    isBtrfs = true;
    isNixos = true;
    isLinux = true;
    isCloud = true;
    proxyHost = "twothreetunnel";
    server = {
      wireguard = {
        isClient = true;
        serverName = "twothreetunnel";
      };
      garage = {
        data_dir = {
          capacity = "150G";
          path = "/var/lib/garage/data";
        };
        keys = {
          nixos = [
            "attic"
          ];
        };
        buckets = [
          "attic"
        ];
      };
    };
  };
} // lib.optionalAttrs (!minimal) {
  swarselprofiles = {
    server = true;
  };

  swarselmodules.server = {
    wireguard = true;
    ssh-builder = true;
    postgresql = true;
    attic = true;
    garage = true;
    hydra = true;
    dns-hostrecord = true;
  };

}
