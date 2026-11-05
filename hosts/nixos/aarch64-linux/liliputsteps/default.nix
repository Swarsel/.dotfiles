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
    self.modules.nixos.bastion
    self.modules.nixos.crowdsec
  ];

  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 1 vCPUs, 8GB RAM";
    isBtrfs = true;
    isCloud = true;
    isCrypted = true;
    isImpermanence = true;
    isLinux = true;
    isSecureBoot = false;
    isSwap = false;
    nodeRoles = [ "jumphost" ];
    rootDisk = "/dev/disk/by-id/scsi-360fb180663ec4f2793a763a087d46885";
  };

  topology.self = {
    icon = "devices.cloud-server";
    interfaces.ProxyJump = {
      physicalConnections = [
        (config.lib.topology.mkConnection "moonside" "lan")
        (config.lib.topology.mkConnection "twothreetunnel" "lan")
        (config.lib.topology.mkConnection "belchsfactory" "lan")
        (config.lib.topology.mkConnection "stoicclub" "lan")
        (config.lib.topology.mkConnection "eagleland" "wan")
      ];
      virtual = true;
    };
  };
}
