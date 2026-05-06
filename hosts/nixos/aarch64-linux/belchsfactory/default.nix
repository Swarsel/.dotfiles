{ self, lib, minimal, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    "${self}/modules/nixos/optional/systemd-networkd-server.nix"
    "${self}/modules/nixos/optional/nix-topology-self.nix"
  ] ++ lib.optionals (!minimal) [
    "${self}/profiles/nixos/localserver"
    "${self}/modules/nixos/server/wireguard.nix"
    "${self}/modules/nixos/server/ssh-builder.nix"
    "${self}/modules/nixos/server/attic.nix"
    "${self}/modules/nixos/server/garage.nix"
    "${self}/modules/nixos/server/buildbot.nix"
  ];

  node.lockFromBootstrapping = lib.mkForce false;

  topology.self = {
    icon = "devices.cloud-server";
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
    isNixos = true;
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
