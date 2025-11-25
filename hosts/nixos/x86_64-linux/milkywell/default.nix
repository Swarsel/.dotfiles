{ lib, config, minimal, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];
  node.lockFromBootstrapping = false;
  sops = {
    age.sshKeyPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  topology.self = {
    icon = "devices.cloud-server";
  };

  networking = {
    domain = "subnet03112148.vcn03112148.oraclevcn.com";
    firewall = {
      allowedTCPPorts = [ 53 ];
    };
  };

  system.stateVersion = "23.11";

  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "VM.Standard.E2.1.Micro";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = false;
    isSwap = true;
    swapSize = "8G";
    rootDisk = "/dev/sda";
    isBtrfs = true;
    isNixos = true;
    isLinux = true;
    server = {
      inherit (config.repo.secrets.local.networking) localNetwork;
    };
  };
} // lib.optionalAttrs (!minimal) {
  swarselprofiles = {
    server = true;
  };

}
