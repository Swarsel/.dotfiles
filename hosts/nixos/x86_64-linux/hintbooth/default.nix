{
  self,
  config,
  lib,
  confLib,
  globals,
  minimal,
  nodes,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    self.modules.nixos.disk-mirrored-root

    self.modules.nixos.systemd-networkd-server-home
    self.modules.nixos.microvm-host
  ]
  ++ lib.optionals minimal [
    self.modules.nixos.server-network
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
    isSwap = false;
    localVLANs = builtins.attrNames globals.networks.home-lan.vlans;
    networkKernelModules = [ "igb" ];
    nodeRoles = [
      "homeProxy"
      "ntpServer"
      "routerServer"
    ];
    rootDisk = "/dev/disk/by-id/ata-TS64GMSA220S_K191160084";
    rootMirrorDisk = "/dev/disk/by-id/ata-Fanxiang_S101_256GB_AA000000000000001538";
    withMicroVMs = true;
  };
  topology.self.interfaces = {
    lan1.physicalConnections = [
      {
        interface = "eth1";
        node = "switch-bedroom";
      }
    ];
    lan2.physicalConnections = [
      {
        interface = "eth1";
        node = "switch-kitchen";
      }
    ];
    lan3.physicalConnections = [
      {
        interface = "lan";
        node = "summers";
      }
    ];
    lan4.physicalConnections = [
      {
        interface = "bmc";
        node = "summers";
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
    ]
    ++ map (guest: "summers-${guest}") (builtins.attrNames nodes.summers.config.guests)
    ++ [ "winters" ];
    netConfigPrefix = "home";
    server = config.node.name;
  };
  zramSwap.enable = true;
}
// lib.optionalAttrs (!minimal) {
  guests = confLib.mkMicrovm "adguardhome" { } // confLib.mkMicrovm "nginx" { };
}
