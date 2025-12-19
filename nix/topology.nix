{ self, inputs, ... }:
{
  imports = [
    inputs.nix-topology.flakeModule
  ];

  perSystem.topology.modules = [
    ({ config, ... }:
      let
        inherit (self.outputs) globals;
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
            inherit (globals.networks.home-lan) cidrv4;
          };
          fritz-wg = {
            name = "Wireguard Tunnel for Fritzbox net access";
            inherit (globals.networks.twothreetunnel-wg) cidrv4;
          };
          wg = {
            name = "Wireguard Tunnel for proxy access";
            inherit (globals.networks.twothreetunnel-wg) cidrv4;
          };
        };

        nodes = {
          internet = mkInternet {
            connections = [
              (mkConnection "fritzbox" "dsl")
              (mkConnection "moonside" "wan")
              (mkConnection "belchsfactory" "wan")
              (mkConnection "twothreetunnel" "wan")
              (mkConnection "stoicclub" "wan")
              (mkConnection "liliputsteps" "wan")
              (mkConnection "eagleland" "wan")
              (mkConnection "magicant" "wifi")
              (mkConnection "toto" "bootstrapper")
              (mkConnection "hotel" "demo host")
            ];
          };


          fritzbox = mkRouter "FRITZ!Box" {
            info = "FRITZ!Box 7682";
            image = "${self}/files/topology-images/hunsn.png";
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
              eth2 = mkConnection "switch-bedroom" "eth1";
              eth3 = mkConnection "switch-livingroom" "eth1";
              eth-wan = mkConnection "hintbooth" "eth6";
              wgPyramid = mkConnection "pyramid" "fritz-wg";
              wgMagicant = mkConnection "magicant" "fritz-wg";
              wifiPyramid = mkConnection "pyramid" "wifi";
              wifiMagicant = mkConnection "magicant" "wifi";
              wifiBakery = mkConnection "bakery" "wifi";
              wifiMachpizza = mkConnection "machpizza" "wifi";
            };
            interfaces = {
              eth1 = {
                addresses = [ globals.networks.home-lan.hosts.fritzbox.ipv4 ];
                network = "home-lan";
              };
              eth2 = {
                addresses = [ globals.networks.home-lan.hosts.fritzbox.ipv4 ];
                network = "home-lan";
              };
              eth3 = {
                addresses = [ globals.networks.home-lan.hosts.fritzbox.ipv4 ];
                network = "home-lan";
              };
              eth-wan = {
                addresses = [ globals.networks.home-lan.hosts.fritzbox.ipv4 ];
                network = "home-lan";
              };
              wifi = {
                addresses = [ globals.networks.home-lan.hosts.fritzbox.ipv4 ];
                virtual = true;
                network = "home-lan";
              };
              fritz-wg = {
                addresses = [ globals.networks.fritz-wg.hosts.fritzbox.ipv4 ];
                network = "wg";
                virtual = true;
                type = "wireguard";
              };
            };
          };

          switch-livingroom = mkSwitch "Switch Livingroom" {
            info = "TL-SG108";
            image = "${self}/files/topology-images/TL-SG108.png";
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
              eth8 = mkConnection "pyramid" "eth1";
            };
          };

          switch-bedroom = mkSwitch "Switch Bedroom" {
            info = "TL-SG1005D";
            image = "${self}/files/topology-images/TL-SG1005D.png";
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
            connections.eth3 = mkConnection "machpizza" "eth1";
          };

          nswitch = mkDevice "Nintendo Switch" {
            info = "Nintendo Switch";
            image = "${self}/files/topology-images/nintendo-switch.png";
            interfaces.eth1 = { };
          };

          magicant = mkDevice "magicant" {
            icon = "${self}/files/topology-images/phone.png";
            info = "Samsung Z Flip 6";
            image = "${self}/files/topology-images/zflip6.png";
            interfaces = {
              wifi = { };
              fritz-wg = { };
            };
          };

          machpizza = mkDevice "machpizza" {
            info = "MacBook Pro 2016";
            icon = "${self}/files/topology-images/mac.png";
            interfaces = {
              eth1 = { };
              wifi = { };
            };
          };

          pc = mkDevice "Windows Gaming Server" {
            info = "i7-4790k, GTX970, 32GB RAM";
            image = "${self}/files/topology-images/pc.png";
            interfaces.eth1 = { };
          };

          printer = mkDevice "Printer" {
            info = "DELL C2665dnf";
            image = "${self}/files/topology-images/DELL-C2665dnf.png";
            interfaces.eth1 = { };
          };

        };

      })


  ];
}
