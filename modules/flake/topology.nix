{
  self,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.nix-topology = {
    inputs = {
      flake-parts.follows = "flake-parts";
      nixpkgs.follows = "nixpkgs";
    };
    url = "github:Swarsel/nix-topology/dev";
  };
}
// lib.optionalAttrs (inputs ? nix-topology) {
  imports = [
    inputs.nix-topology.flakeModule
  ];

  perSystem =
    { system, ... }:
    let
      inherit (self.outputs) lib;
    in
    {
      topology.modules = [
        (
          { config, ... }:
          let
            globals = self.outputs.globals.${system};
            inherit (config.lib.topology)
              mkConnection
              mkDevice
              mkInternet
              mkRouter
              mkSwitch
              ;
          in
          {
            networks = {
              services = {
                inherit (globals.networks.home-lan.vlans.services) cidrv4 cidrv6;
                name = "VLAN: Services";
              };
              devices = {
                inherit (globals.networks.home-lan.vlans.devices) cidrv4 cidrv6;
                name = "VLAN: Devices";
              };
              fritz-lan = {
                inherit (globals.networks.home-lan) cidrv4 cidrv6;
                name = "Fritz!Box LAN";
              };
              fritz-wg = {
                inherit (globals.networks.fritz-wg) cidrv4 cidrv6;
                name = "WireGuard: Fritz!Box tunnel";
              };
              guests = {
                inherit (globals.networks.home-lan.vlans.guests) cidrv4 cidrv6;
                name = "VLAN: Guests";
              };
              home = {
                inherit (globals.networks.home-lan.vlans.home) cidrv4 cidrv6;
                name = "VLAN: Home";
              };
              wgHome = {
                inherit (globals.networks.home-wgHome) cidrv4 cidrv6;
                name = "WireGuard: Home proxy tunnel";
              };
              wgProxy = {
                inherit (globals.networks.twothreetunnel-wgProxy) cidrv4 cidrv6;
                name = "WireGuard: Web proxy tunnel";
              };
            };
            renderer = "elk";
            nodes = {
              ender3 = mkDevice "Ender 3" {
                services.octoprint = {
                  icon = "${self}/files/topology-images/octoprint.png";
                  name = "OctoPrint";
                };
                deviceIcon = "${self}/files/topology-images/ender3.png";
                icon = "${self}/files/topology-images/raspi.png";
                info = "SKR V1.3, TMC2209 (Dual), TFT35";
                interfaces.eth1 = { };
              };
              fritzbox = mkRouter "FRITZ!Box" {
                connections = {
                  eth-wan = mkConnection "hintbooth" "lan";
                  eth1 = mkConnection "winters" "eth1";
                };
                image = "${self}/files/topology-images/Fritz!Box_7682.png";
                info = "FRITZ!Box 7682";
                interfaceGroups = [
                  [
                    "eth1"
                    "eth2"
                    "eth3"
                    "eth-wan"
                    "wifi"
                  ]
                  [ "dsl" ]
                ];
                interfaces = {
                  eth-wan = {
                    addresses = [ globals.networks.home-lan.hosts.fritzbox.ipv4 ];
                    network = "fritz-lan";
                  };
                  eth1 = {
                    addresses = [ globals.networks.home-lan.hosts.fritzbox.ipv4 ];
                    network = "fritz-lan";
                  };
                  eth2 = { };
                  eth3 = { };
                  fritz-wg = {
                    addresses = [ globals.networks.fritz-wg.hosts.fritzbox.ipv4 ];
                    network = "fritz-wg";
                    physicalConnections = [
                      (mkConnection "pyramid" "fritz-wg")
                      (mkConnection "magicant" "fritz-wg")
                    ];
                    renderer.hidePhysicalConnections = true;
                    type = "wireguard";
                    virtual = true;
                  };
                  wifi = {
                    addresses = [ globals.networks.home-lan.hosts.fritzbox.ipv4 ];
                    network = "fritz-lan";
                    physicalConnections = [
                      (mkConnection "pyramid" "wifi")
                      (mkConnection "bakery" "wifi")
                      (mkConnection "machpizza" "wifi")
                    ];
                    renderer.hidePhysicalConnections = true;
                    virtual = true;
                  };
                };
              };
              internet = mkInternet {
                connections = [
                  (mkConnection "fritzbox" "dsl")
                  (mkConnection "magicant" "wifi")
                  (mkConnection "liliputsteps" "lan")
                  (mkConnection "treehouse" "eth1")
                  (mkConnection "toto" "bootstrapper")
                  (mkConnection "hotel" "demo host")
                ];
              };
              machpizza = mkDevice "machpizza" {
                deviceIcon = "${self}/files/topology-images/mac.png";
                icon = "devices.laptop";
                info = "MacBook Pro 2016";
                interfaces = {
                  eth1.network = "guests";
                  wifi = { };
                };
              };
              magicant = mkDevice "magicant" {
                icon = "${self}/files/topology-images/phone.png";
                image = "${self}/files/topology-images/zflip6.png";
                info = "Samsung Z Flip 6";
                interfaces = {
                  fritz-wg.network = "fritz-wg";
                  wifi = { };
                };
              };
              nswitch = mkDevice "Nintendo Switch" {
                image = "${self}/files/topology-images/nintendo-switch.png";
                info = "Atmosphère 1.3.2 @ FW 19.0.1";
                interfaces.eth1 = { };
              };
              pc = mkDevice "Chaostheater" {
                services.sunshine = {
                  icon = "${self}/files/topology-images/sunshine.png";
                  name = "Sunshine";
                };
                deviceIcon = "${self}/files/topology-images/atlasos.png";
                icon = "${self}/files/topology-images/windows.png";
                info = "ASUS Z97-A, i7-4790k, GTX970, 32GB RAM";
                interfaces.eth1.network = "guests";
              };
              printer = mkDevice "Printer" {
                image = "${self}/files/topology-images/DELL-C2665dnf.png";
                info = "DELL C2665dnf";
                interfaces.eth1 = { };
              };
              ps4 = mkDevice "PlayStation 4" {
                image = "${self}/files/topology-images/ps4.png";
                info = "GoldHEN @ FW 5.05";
                interfaces.eth1 = { };
              };
              switch-bedroom = mkSwitch "Switch Bedroom" {
                connections = {
                  eth2 = mkConnection "printer" "eth1";
                  eth3 = mkConnection "machpizza" "eth1";
                };
                image = "${self}/files/topology-images/Cisco_SG_200-08.png";
                info = "Cisco SG 200-08";
                interfaceGroups = [
                  # trunk
                  [ "eth1" ]
                  # devices
                  [ "eth2" ]
                  # guests
                  [
                    "eth3"
                    "eth4"
                    "eth5"
                    "eth6"
                    "eth7"
                    "eth8"
                  ]
                ];
                interfaces = {
                  eth2.network = lib.mkForce "devices";
                  eth3.network = lib.mkForce "guests";
                };
              };
              switch-livingroom = mkSwitch "Switch Livingroom" {
                connections = {
                  eth2 = mkConnection "nswitch" "eth1";
                  eth3 = mkConnection "bakery" "eth1";
                  eth5 = mkConnection "ps4" "eth1";
                  eth6 = mkConnection "ender3" "eth1";
                  eth7 = mkConnection "pc" "eth1";
                  eth8 = mkConnection "pyramid" "eth1";
                };
                image = "${self}/files/topology-images/TL-SG108E.png";
                info = "TL-SG108E";
                interfaceGroups = [
                  # trunk
                  [ "eth1" ]
                  # devices
                  [
                    "eth2"
                    "eth5"
                    "eth6"
                  ]
                  # home
                  [
                    "eth3"
                    "eth8"
                  ]
                  # guests
                  [
                    "eth4"
                    "eth7"
                  ]
                ];
                interfaces = {
                  eth2.network = lib.mkForce "devices";
                  eth3.network = lib.mkForce "home";
                  eth5.network = lib.mkForce "devices";
                  eth6.network = lib.mkForce "devices";
                  eth7.network = lib.mkForce "guests";
                  eth8.network = lib.mkForce "home";
                };
              };
              treehouse = mkDevice "treehouse" {
                services = {
                  comfyui = {
                    icon = "${self}/files/topology-images/comfyui.png";
                    name = "Comfy UI";
                  };
                  ollama = {
                    icon = "services.ollama";
                    name = "Ollama";
                  };
                  openwebui = {
                    icon = "services.open-webui";
                    name = "Open WebUI";
                  };
                };
                deviceIcon = "${self}/files/topology-images/dgxos.png";
                icon = "${self}/files/topology-images/home-manager.png";
                info = "NVIDIA DGX Spark";
                interfaces = {
                  eth1 = { };
                  wifi = { };
                };
              };

            };

          }
        )

      ];
    };
}
