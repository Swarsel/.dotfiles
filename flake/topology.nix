{ self, inputs, ... }:
{
  imports = [
    inputs.nix-topology.flakeModule
  ];

  perSystem = { system, ... }:
    let
      inherit (self.outputs) lib;
    in
    {
      topology.modules = [
        ({ config, ... }:
          let
            globals = self.outputs.globals.${system};
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
              fritz-lan = {
                name = "Fritz!Box LAN";
                inherit (globals.networks.home-lan) cidrv4 cidrv6;
              };
              services = {
                name = "VLAN: Services";
                inherit (globals.networks.home-lan.vlans.services) cidrv4 cidrv6;
              };
              home = {
                name = "VLAN: Home";
                inherit (globals.networks.home-lan.vlans.home) cidrv4 cidrv6;
              };
              devices = {
                name = "VLAN: Devices";
                inherit (globals.networks.home-lan.vlans.devices) cidrv4 cidrv6;
              };
              guests = {
                name = "VLAN: Guests";
                inherit (globals.networks.home-lan.vlans.guests) cidrv4 cidrv6;
              };
              fritz-wg = {
                name = "WireGuard: Fritz!Box tunnel";
                inherit (globals.networks.fritz-wg) cidrv4 cidrv6;
              };
              wgProxy = {
                name = "WireGuard: Web proxy tunnel";
                inherit (globals.networks.twothreetunnel-wgProxy) cidrv4 cidrv6;
              };
              wgHome = {
                name = "WireGuard: Home proxy tunnel";
                inherit (globals.networks.home-wgHome) cidrv4 cidrv6;
              };
            };

            nodes = {
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


              fritzbox = mkRouter "FRITZ!Box" {
                info = "FRITZ!Box 7682";
                image = "${self}/files/topology-images/Fritz!Box_7682.png";
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

                connections = {
                  eth1 = mkConnection "winters" "eth1";
                  eth-wan = mkConnection "hintbooth" "lan";
                };
                interfaces = {
                  eth1 = {
                    addresses = [ globals.networks.home-lan.hosts.fritzbox.ipv4 ];
                    network = "fritz-lan";
                  };
                  eth2 = { };
                  eth3 = { };
                  eth-wan = {
                    addresses = [ globals.networks.home-lan.hosts.fritzbox.ipv4 ];
                    network = "fritz-lan";
                  };
                  wifi = {
                    addresses = [ globals.networks.home-lan.hosts.fritzbox.ipv4 ];
                    virtual = true;
                    renderer.hidePhysicalConnections = true;
                    network = "fritz-lan";
                    physicalConnections = [
                      (mkConnection "pyramid" "wifi")
                      (mkConnection "bakery" "wifi")
                      (mkConnection "machpizza" "wifi")
                    ];
                  };
                  fritz-wg = {
                    addresses = [ globals.networks.fritz-wg.hosts.fritzbox.ipv4 ];
                    network = "fritz-wg";
                    virtual = true;
                    renderer.hidePhysicalConnections = true;
                    type = "wireguard";
                    physicalConnections = [
                      (mkConnection "pyramid" "fritz-wg")
                      (mkConnection "magicant" "fritz-wg")
                    ];
                  };
                };
              };

              switch-livingroom = mkSwitch "Switch Livingroom" {
                info = "TL-SG108E";
                image = "${self}/files/topology-images/TL-SG108E.png";
                interfaceGroups = [
                  # trunk
                  [ "eth1" ]
                  # devices
                  [ "eth2" "eth5" "eth6" ]
                  # home
                  [ "eth3" "eth8" ]
                  # guests
                  [ "eth4" "eth7" ]
                ];
                interfaces = {
                  eth2 = { network = lib.mkForce "devices"; };
                  eth3 = { network = lib.mkForce "home"; };
                  eth5 = { network = lib.mkForce "devices"; };
                  eth6 = { network = lib.mkForce "devices"; };
                  eth7 = { network = lib.mkForce "guests"; };
                  eth8 = { network = lib.mkForce "home"; };
                };
                connections = {
                  eth2 = mkConnection "nswitch" "eth1";
                  eth3 = mkConnection "bakery" "eth1";
                  eth5 = mkConnection "ps4" "eth1";
                  eth6 = mkConnection "ender3" "eth1";
                  eth7 = mkConnection "pc" "eth1";
                  eth8 = mkConnection "pyramid" "eth1";
                };
              };

              switch-bedroom = mkSwitch "Switch Bedroom" {
                info = "Cisco SG 200-08";
                image = "${self}/files/topology-images/Cisco_SG_200-08.png";
                interfaceGroups = [
                  # trunk
                  [ "eth1" ]
                  # devices
                  [ "eth2" ]
                  # guests
                  [ "eth3" "eth4" "eth5" "eth6" "eth7" "eth8" ]
                ];
                interfaces = {
                  eth2 = { network = lib.mkForce "devices"; };
                  eth3 = { network = lib.mkForce "guests"; };
                };
                connections = {
                  eth2 = mkConnection "printer" "eth1";
                  eth3 = mkConnection "machpizza" "eth1";
                };
              };

              nswitch = mkDevice "Nintendo Switch" {
                info = "Atmosphère 1.3.2 @ FW 19.0.1";
                image = "${self}/files/topology-images/nintendo-switch.png";
                interfaces.eth1 = { };
              };

              ps4 = mkDevice "PlayStation 4" {
                info = "GoldHEN @ FW 5.05";
                image = "${self}/files/topology-images/ps4.png";
                interfaces.eth1 = { };
              };

              ender3 = mkDevice "Ender 3" {
                info = "SKR V1.3, TMC2209 (Dual), TFT35";
                deviceIcon = "${self}/files/topology-images/ender3.png";
                icon = "${self}/files/topology-images/raspi.png";
                interfaces.eth1 = { };
                services = {
                  octoprint = {
                    name = "OctoPrint";
                    icon = "${self}/files/topology-images/octoprint.png";
                  };
                };
              };

              magicant = mkDevice "magicant" {
                icon = "${self}/files/topology-images/phone.png";
                info = "Samsung Z Flip 6";
                image = "${self}/files/topology-images/zflip6.png";
                interfaces = {
                  wifi = { };
                  fritz-wg.network = "fritz-wg";
                };
              };

              machpizza = mkDevice "machpizza" {
                info = "MacBook Pro 2016";
                icon = "devices.laptop";
                deviceIcon = "${self}/files/topology-images/mac.png";
                interfaces = {
                  eth1.network = "guests";
                  wifi = { };
                };
              };

              treehouse = mkDevice "treehouse" {
                info = "NVIDIA DGX Spark";
                icon = "${self}/files/topology-images/home-manager.png";
                deviceIcon = "${self}/files/topology-images/dgxos.png";
                interfaces = {
                  eth1 = { };
                  wifi = { };
                };
                services = {
                  ollama = {
                    name = "Ollama";
                    icon = "services.ollama";
                  };
                  openwebui = {
                    name = "Open WebUI";
                    icon = "services.open-webui";
                  };
                  comfyui = {
                    name = "Comfy UI";
                    icon = "${self}/files/topology-images/comfyui.png";
                  };
                };
              };

              pc = mkDevice "Chaostheater" {
                info = "ASUS Z97-A, i7-4790k, GTX970, 32GB RAM";
                icon = "${self}/files/topology-images/windows.png";
                deviceIcon = "${self}/files/topology-images/atlasos.png";
                services = {
                  sunshine = {
                    name = "Sunshine";
                    icon = "${self}/files/topology-images/sunshine.png";
                  };
                };
                interfaces.eth1.network = "guests";
              };

              printer = mkDevice "Printer" {
                info = "DELL C2665dnf";
                image = "${self}/files/topology-images/DELL-C2665dnf.png";
                interfaces.eth1 = { };
              };

            };

          })


      ];
    };
}
