{
  flake.modules.nixos.zigbee2mqtt =
    {
      self,
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit (config.swarselsystems) sopsFile;
      inherit
        (confLib.gen {
          dir = "/var/lib/zigbee2mqtt";
          name = "zigbee2mqtt";
          port = 8080;
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
        idmServer
        isHome
        nginxAccessRules
        webProxy
        ;
      coordinator = globals.networks.home-lan.vlans.iot.hosts.slzb-06m;
      mqttListener = lib.head config.services.mosquitto.listeners;
    in
    {
      imports = [ self.modules.nixos.mosquitto ];
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
        sops.secrets.zigbee2mqtt-env = {
          inherit sopsFile;
          group = serviceGroup;
          mode = "0440";
          owner = serviceUser;
        };
        services.${serviceName} = {
          enable = true;
          settings = {
            advanced.channel = 20;
            frontend = {
              enabled = true;
              port = servicePort;
              url = "https://${serviceDomain}";
            };
            mqtt.server = "mqtt://${mqttListener.address}:${toString mqttListener.port}";
            serial = {
              adapter = "ember";
              baudrate = 115200;
              port = "tcp://${coordinator.ipv4}:6638";
              rtscts = false;
            };
          };
        };
        environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
          {
            directory = serviceDir;
            group = serviceGroup;
            user = serviceUser;
          }
        ];
        systemd.services.${serviceName} = {
          after = [ "mosquitto.service" ];
          serviceConfig.EnvironmentFile = config.sops.secrets.zigbee2mqtt-env.path;
          wants = [ "mosquitto.service" ];
        };
        nodes = lib.mkMerge [
          {
            ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; };
          }
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              oauth2 = true;
              oauth2Groups = [ "${serviceName}_access" ];
              proxyWebsockets = true;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                oauth2 = true;
                oauth2Groups = [ "${serviceName}_access" ];
                proxyWebsockets = true;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];
      };
    }

  ;
}
