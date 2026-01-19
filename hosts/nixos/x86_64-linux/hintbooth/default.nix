{ self, config, lib, minimal, confLib, globals, ... }:
{

  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    "${self}/modules/nixos/optional/systemd-networkd-server-home.nix"
    "${self}/modules/nixos/optional/microvm-host.nix"
  ];

  topology.self = {
    interfaces = {
      lan2.physicalConnections = [{ node = "summers"; interface = "lan"; }];
      lan3.physicalConnections = [{ node = "summers"; interface = "bmc"; }];
      lan4.physicalConnections = [{ node = "switch-bedroom"; interface = "eth1"; }];
      lan5.physicalConnections = [{ node = "switch-livingroom"; interface = "eth1"; }];
    };
  };

  globals.general = {
    homeProxy = config.node.name;
    routerServer = config.node.name;
  };

  swarselsystems = {
    info = "HUNSN RM02, 8GB RAM";
    flakePath = "/root/.dotfiles";
    isImpermanence = true;
    isSecureBoot = true;
    isCrypted = true;
    isBtrfs = true;
    isLinux = true;
    isNixos = true;
    rootDisk = "/dev/sda";
    swapSize = "8G";
    networkKernelModules = [ "igb" ];
    withMicroVMs = true;
    localVLANs = map (name: "${name}") (builtins.attrNames globals.networks.home-lan.vlans);
    initrdVLAN = "home";
    server = {
      wireguard.interfaces = {
        wgHome = {
          isServer = true;
          peers = [
            "hintbooth-adguardhome"
            "hintbooth-nginx"
            "summers"
            "summers-ankisync"
            "summers-atuin"
            "summers-audio"
            "summers-firefly"
            "summers-forgejo"
            "summers-freshrss"
            "summers-homebox"
            "summers-immich"
            "summers-jellyfin"
            "summers-kanidm"
            "summers-kavita"
            "summers-koillection"
            "summers-matrix"
            "summers-monitoring"
            "summers-nextcloud"
            "summers-paperless"
            "summers-radicale"
            "summers-storage"
            "summers-transmission"
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
    // confLib.mkMicrovm "adguardhome" { }
    // confLib.mkMicrovm "nginx" { }
  );

}
