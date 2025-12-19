{ self, lib, minimal, ... }:
{

  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    "${self}/modules/nixos/optional/systemd-networkd-server.nix"
  ];

  topology.self = {
    interfaces = {
      "eth1" = { };
      "eth2" = { };
      "eth3" = { };
      "eth4" = { };
      "eth5" = { };
      "eth6" = { };
    };
  };

  swarselsystems = {
    info = "HUNSN RM02, 8GB RAM";
    flakePath = "/root/.dotfiles";
    isImpermanence = true;
    isSecureBoot = false;
    isCrypted = true;
    isBtrfs = true;
    isLinux = true;
    isNixos = true;
    rootDisk = "/dev/sda";
    swapSize = "8G";
    networkKernelModules = [ "igb" ];
  };

} // lib.optionalAttrs (!minimal) {

  swarselprofiles = {
    server = true;
    router = false;
  };

  swarselmodules = {
    server = {
      nginx = lib.mkForce false; # we get this from the server profile
    };
  };

}
