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

  node.lockFromBootstrapping = lib.mkForce false;

  topology.self = {
    icon = "devices.cloud-server";
  };

  # use SSH key with own limits for nixbuild.net instead of the general one in remotebuild.nix
  sops.secrets.nixbuild-net-key = lib.mkForce {
    inherit (config.swarselsystems) sopsFile;
    mode = "0400";
  };

  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 4 vCPUs, 24GB RAM";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isSwap = false;
    rootDisk = "/dev/sda";
    isBtrfs = true;
    isLinux = true;
    isCloud = true;
    proxyHost = "twothreetunnel";
    server = {
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
}
