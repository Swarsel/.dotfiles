{ self, config, lib, minimal, confLib, globals, ... }:
{

  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    self.modules.nixos.systemd-networkd-server-home
    self.modules.nixos.microvm-host
  ] ++ lib.optionals (!minimal) [
    self.modules.nixos.wireguard
    self.modules.nixos.profile-localserver
    self.modules.nixos.profile-router
    self.modules.nixos.smartctl-exporter
  ];

  topology.self = {
    interfaces = {
      lan2.physicalConnections = [{ node = "summers"; interface = "lan"; }];
      lan3.physicalConnections = [{ node = "summers"; interface = "bmc"; }];
      lan4.physicalConnections = [{ node = "switch-bedroom"; interface = "eth1"; }];
      lan5.physicalConnections = [{ node = "switch-livingroom"; interface = "eth1"; }];
    };
  };

  globals = {
    wireguard.wgHome = {
      server = config.node.name;
      netConfigPrefix = "home";
      clients = [
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
        "summers-mealie"
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

  swarselsystems = {
    nodeRoles = [ "homeProxy" "routerServer" ];
    info = "HUNSN RM02, 8GB RAM";
    flakePath = "/root/.dotfiles";
    isImpermanence = true;
    isSecureBoot = true;
    isCrypted = true;
    isBtrfs = true;
    isLinux = true;
    rootDisk = "/dev/sda";
    swapSize = "8G";
    networkKernelModules = [ "igb" ];
    withMicroVMs = true;
    localVLANs = map (name: "${name}") (builtins.attrNames globals.networks.home-lan.vlans);
    initrdVLAN = "home";
  };

} // lib.optionalAttrs (!minimal) {

  guests = lib.mkIf (!minimal && config.swarselsystems.withMicroVMs) (
    { }
    // confLib.mkMicrovm "adguardhome" { }
    // confLib.mkMicrovm "nginx" { }
  );

}
