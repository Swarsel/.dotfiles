{
  flake-file.inputs.nixos-home-assistant = {
    inputs = {
      flake-parts.follows = "flake-parts";
      git-hooks-nix.follows = "pre-commit-hooks";
      nixpkgs.follows = "nixpkgs";
      pedantix.follows = "pedantix";
      treefmt-nix.follows = "treefmt-nix";
    };
    url = "github:Swarsel/nixos-home-assistant";
  };

  flake.modules.nixos.home-assistant =
    {
      self,
      inputs,
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          dir = "/var/lib/hass";
          name = "home-assistant";
          port = 8123;
          user = "hass";
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDir
        serviceDomain
        serviceGroup
        serviceName
        servicePort
        serviceUser
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        isHome
        nginxAccessRules
        webProxy
        ;
      inherit (config.repo.secrets.common) location;
      mqttListener = lib.head config.services.mosquitto.listeners;
    in
    {
      imports = [
        inputs.nixos-home-assistant.nixosModules.default
        self.modules.nixos.mosquitto
      ];
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName}.info = "https://${serviceDomain}";
        globals = {
          services = confLib.mkServiceGlobal {
            inherit
              homeServiceAddress
              isHome
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDomain
              serviceName
              ;
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring = {
            http = confLib.mkHttpMonitoring { inherit serviceName servicePort; };
            systemd = confLib.mkSystemdMonitoring {
              inherit serviceName;
              unit = "${serviceName}.service";
            };
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops.secrets.home-assistant-admin-pw = { };
        services.${serviceName} = {
          config = {
            default_config = { };
            homeassistant = {
              inherit (location) latitude longitude;
              external_url = "https://${serviceDomain}";
              name = "Home";
              time_zone = location.timezone;
              unit_system = "metric";
            };
            http = {
              server_port = servicePort;
              trusted_proxies = [
                "127.0.0.1"
                "::1"
              ]
              ++
                lib.concatMap
                  (net: [
                    net.cidrv4
                    net.cidrv6
                  ])
                  [
                    globals.networks."${globals.wireguard.wgHome.netConfigPrefix}-wgHome"
                    globals.networks."${globals.wireguard.wgProxy.netConfigPrefix}-wgProxy"
                  ];
              use_x_forwarded_for = true;
            };
          };
          enable = true;
          extraComponents = [
            "default_config"
            "isal"
            "met"
            "mqtt"
            "radio_browser"
          ];
          provision = {
            enable = true;
            areas = {
              bedroom.name = "Bedroom";
              kitchen.name = "Kitchen";
              living_room.name = "Living Room";
            };
            entries = {
              met = {
                domain = "met";
                steps = [ { } ];
              };
              mqtt = {
                domain = "mqtt";
                steps = [
                  {
                    inherit (mqttListener) port;
                    broker = mqttListener.address;
                  }
                ];
              };
            };
            owner = {
              name = config.repo.secrets.common.fullName;
              passwordFile = config.sops.secrets.home-assistant-admin-pw.path;
              username = config.swarselsystems.mainUser;
            };
            removeOnboardingIntegrations = true;
            url = "http://127.0.0.1:${toString servicePort}";
          };
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            group = serviceGroup;
            user = serviceUser;
          }
        ];
        nodes = lib.mkMerge [
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              proxyWebsockets = true;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                proxyWebsockets = true;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];
      };
    };
}
