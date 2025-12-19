{ self, lib, minimal, ... }:
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

  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.A1.Flex, 1 vCPUs, 8GB RAM";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isSwap = false;
    rootDisk = "/dev/disk/by-id/scsi-360fb180663ec4f2793a763a087d46885";
    isBtrfs = true;
    isNixos = true;
    isLinux = true;
    isCloud = true;
    mainUser = "jump";
  };
} // lib.optionalAttrs (!minimal) {
  swarselprofiles = {
    server = true;
  };

  swarselmodules.server = {
    nginx = false;
    bastion = true;
    dns-hostrecord = true;
    # ssh = false;
  };

  # users.users.swarsel.enable = lib.mkForce false;
  # home-manager.users.swarsel.enable = lib.mkForce false
}
