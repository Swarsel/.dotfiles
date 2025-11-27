{ lib, config, minimal, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
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
    proxyHost = "belchsfactory";
    server = {
      inherit (config.repo.secrets.local.networking) localNetwork;
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
    postgresql = lib.mkDefault true;
    attic = lib.mkDefault true;
    garage = lib.mkDefault true;
  };

}
