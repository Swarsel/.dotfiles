{ self, config, lib, minimal, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    self.modules.nixos.systemd-networkd-server
    self.modules.nixos.nix-topology-self
  ] ++ lib.optionals (!minimal) [
    self.modules.nixos.profile-localserver
    self.modules.nixos.bastion
  ];

  topology.self = {
    icon = "devices.cloud-server";
    interfaces.ProxyJump = {
      virtual = true;
      physicalConnections = [
        (config.lib.topology.mkConnection "moonside" "lan")
        (config.lib.topology.mkConnection "twothreetunnel" "lan")
        (config.lib.topology.mkConnection "belchsfactory" "lan")
        (config.lib.topology.mkConnection "stoicclub" "lan")
        (config.lib.topology.mkConnection "eagleland" "wan")
      ];
    };
  };

  swarselsystems = {
    nodeRoles = [ "jumphost" ];
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 1 vCPUs, 8GB RAM";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isSwap = false;
    rootDisk = "/dev/disk/by-id/scsi-360fb180663ec4f2793a763a087d46885";
    isBtrfs = true;
    isLinux = true;
    isCloud = true;
    mainUser = "jump";
  };
} // lib.optionalAttrs (!minimal) {

  # users.users.swarsel.enable = lib.mkForce false;
  # home-manager.users.swarsel.enable = lib.mkForce false
}
