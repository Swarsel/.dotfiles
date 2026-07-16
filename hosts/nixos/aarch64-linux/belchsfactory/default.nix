{
  self,
  inputs,
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
    self.modules.nixos.wireguard
    self.modules.nixos.ssh-builder
    self.modules.nixos.attic
    self.modules.nixos.garage
    self.modules.nixos.buildbot
    inputs.self.modules.nixos.remotebuild
  ];

  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 4 vCPUs, 24GB RAM";
    isBtrfs = true;
    isCloud = true;
    isCrypted = true;
    isImpermanence = true;
    isLinux = true;
    isSecureBoot = false;
    isSwap = false;
    proxyHost = "twothreetunnel";
    rootDisk = "/dev/sda";
    server = {
      garage = {
        buckets = [
          "attic"
        ];
        data_dir = {
          capacity = "150G";
          path = "/var/lib/garage/data";
        };
        keys = {
          nixos = [
            "attic"
          ];
        };
      };
    };
  };

  topology.self = {
    icon = "devices.cloud-server";
  };

  # use SSH key with own limits for nixbuild.net instead of the general one in remotebuild.nix
  sops.secrets.nixbuild-net-key = lib.mkForce {
    inherit (config.swarselsystems) sopsFile;
    mode = "0400";
  };

  node.lockFromBootstrapping = lib.mkForce false;
}
