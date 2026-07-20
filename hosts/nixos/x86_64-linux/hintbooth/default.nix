{
  self,
  config,
  lib,
  confLib,
  globals,
  minimal,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    self.modules.nixos.systemd-networkd-server-home
    self.modules.nixos.microvm-host
  ]
  ++ lib.optionals (!minimal) [
    self.modules.nixos.wireguard
    self.modules.nixos.profile-localserver
    self.modules.nixos.profile-router
    self.modules.nixos.smartctl-exporter
  ];
  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "HUNSN RM02, 8GB RAM";
    initrdVLAN = "home";
    isBtrfs = true;
    isCrypted = true;
    isImpermanence = true;
    isLinux = true;
    isSecureBoot = true;
    localVLANs = map (name: "${name}") (builtins.attrNames globals.networks.home-lan.vlans);
    networkKernelModules = [ "igb" ];
    nodeRoles = [
      "homeProxy"
      "routerServer"
    ];
    rootDisk = "/dev/sda";
    swapSize = "8G";
    withMicroVMs = true;
  };
  topology.self.interfaces = {
    lan2.physicalConnections = [
      {
        interface = "lan";
        node = "summers";
      }
    ];
    lan3.physicalConnections = [
      {
        interface = "bmc";
        node = "summers";
      }
    ];
    lan4.physicalConnections = [
      {
        interface = "eth1";
        node = "switch-bedroom";
      }
    ];
    lan5.physicalConnections = [
      {
        interface = "eth1";
        node = "switch-livingroom";
      }
    ];
  };
  globals.wireguard.wgHome = {
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
    netConfigPrefix = "home";
    server = config.node.name;
  };

}
// lib.optionalAttrs (!minimal) {

  guests = lib.mkIf (!minimal && config.swarselsystems.withMicroVMs) (
    { } // confLib.mkMicrovm "adguardhome" { } // confLib.mkMicrovm "nginx" { }
  );

}
