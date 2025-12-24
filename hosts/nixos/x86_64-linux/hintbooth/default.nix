{ self, config, lib, minimal, confLib, ... }:
{

  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    "${self}/modules/nixos/optional/systemd-networkd-server.nix"
    "${self}/modules/nixos/optional/systemd-networkd-vlan.nix"
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
    withMicroVMs = true;
    server = {
      wireguard.interfaces = {
        wgHome = {
          isServer = true;
          peers = [
            "winters"
          ];
        };
      };
    };
  };

} // lib.optionalAttrs (!minimal) {

  swarselprofiles = {
    server = true;
    router = true;
  };

  swarselmodules = {
    server = {
      wireguard = true;
    };
  };

  guests = lib.mkIf (!minimal && config.swarselsystems.withMicroVMs) (
    { }
    // confLib.mkMicrovm "adguardhome"
  );

}
