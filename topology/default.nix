{ config, ... }:
let
  inherit (config.lib.topology)
    mkInternet
    mkDevice
    mkSwitch
    mkRouter
    mkConnection
    ;
in
{
  renderer = "elk";

  networks = {
    home-lan = {
      name = "Home LAN";
      cidrv4 = "192.168.1.0/24";
    };
    wg = {
      name = "Wireguard Tunnel";
      cidrv4 = "192.168.3.0/24";
    };
  };

  nodes = {
    internet = mkInternet {
      connections = [
        (mkConnection "moonside" "wan")
        (mkConnection "pfsense" "wan")
        (mkConnection "sync" "wan")
        (mkConnection "toto" "bootstrapper")
        (mkConnection "drugstore" "installer image")
        (mkConnection "chaostheatre" "demo host")
      ];
    };

    chaostheatre.interfaces."demo host" = { };
    drugstore.interfaces."installer image" = { };
    toto.interfaces."bootstrapper" = { };
    sync.interfaces.wan = { };
    moonside.interfaces.wan = { };

    pfsense = mkRouter "pfSense" {
      info = "HUNSN RM02";
      image = ../topology/images/hunsn.png;
      interfaceGroups = [
        [
          "eth2"
          "eth3"
          "eth4"
          "eth5"
          "eth6"
        ]
        [ "wan" ]
      ];
      interfaces.wg = {
        addresses = [ "192.168.3.1" ];
        network = "wg";
        virtual = true;
        type = "wireguard";
      };

      connections = {
        eth2 = mkConnection "switch-livingroom" "eth1";
        eth4 = mkConnection "winters" "eth1";
        eth3 = mkConnection "switch-bedroom" "eth1";
        eth6 = mkConnection "wifi-ap" "eth1";
        wg = mkConnection "moonside" "wg";
      };
      interfaces = {
        eth2 = {
          addresses = [ "192.168.1.1" ];
          network = "home-lan";
        };
        eth3 = {
          addresses = [ "192.168.1.1" ];
          network = "home-lan";
        };
        eth4 = {
          addresses = [ "192.168.1.1" ];
          network = "home-lan";
        };
        eth6 = {
          addresses = [ "192.168.1.1" ];
          network = "home-lan";
        };
      };
    };

    winters.interfaces."eth1" = { };

    wifi-ap = mkSwitch "Wi-Fi AP" {
      info = "Huawei";
      image = ../topology/images/huawei.png;
      interfaceGroups = [
        [
          "eth1"
          "wifi"
        ]
      ];
    };

    switch-livingroom = mkSwitch "Switch Livingroom" {
      info = "TL-SG108";
      image = ../topology/images/TL-SG108.png;
      interfaceGroups = [
        [
          "eth1"
          "eth2"
          "eth3"
          "eth4"
          "eth5"
          "eth6"
          "eth7"
          "eth8"
        ]
      ];
      connections = {
        eth2 = mkConnection "nswitch" "eth1";
        eth7 = mkConnection "pc" "eth1";
        eth8 = mkConnection "nbl-imba-2" "eth1";
      };
    };

    nswitch = mkDevice "Nintendo Switch" {
      info = "Nintendo Switch";
      image = ../topology/images/nintendo-switch.png;
      interfaces.eth1 = { };
    };

    pc = mkDevice "Windows Gaming Server" {
      info = "i7-4790k, GTX970, 32GB RAM";
      image = ../topology/images/pc.png;
      interfaces.eth1 = { };
    };

    nbl-imba-2.interfaces.eth1 = { };

    switch-bedroom = mkSwitch "Switch Bedroom" {
      info = "TL-SG1005D";
      image = ../topology/images/TL-SG1005D.png;
      interfaceGroups = [
        [
          "eth1"
          "eth2"
          "eth3"
          "eth4"
          "eth5"
        ]
      ];
      connections.eth2 = mkConnection "printer" "eth1";
    };

    printer = mkDevice "Printer" {
      info = "DELL C2665dnf";
      image = ../topology/images/DELL-C2665dnf.png;
      interfaces.eth1 = { };
    };

  };

}
