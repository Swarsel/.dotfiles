{
  flake.modules.nixos.server-syncthing =
    {
      config,
      lib,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "syncthing";
          port = 8384;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceGroup
        serviceName
        servicePort
        serviceUser
        ;
      inherit (confLib.static)
        homeProxyIf
        homeServiceAddress
        homeWebProxy
        isHome
        isProxied
        nginxAccessRules
        webProxy
        webProxyIf
        ;

      specificServiceName = "${serviceName}-${config.node.name}";
      serviceDomain = globals.services.${specificServiceName}.domain;
      inherit (globals.services.${specificServiceName}) extraConfig;

      cfg = config.services.${serviceName};
      baseDevices = config.repo.secrets.common.syncthing.devices;
      syncDevices = builtins.attrNames baseDevices ++ (extraConfig.extraSyncDevices or [ ]);
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "syncthing" ];
        # networking.firewall.allowedTCPPorts = [ servicePort ];
        globals = {
          services.${specificServiceName} = {
            inherit
              isHome
              proxyAddress4
              proxyAddress6
              serviceAddress
              ;
            domain = lib.mkDefault config.repo.secrets.common.services.domains.${specificServiceName};
            extraConfig.devices = baseDevices;
            homeServiceAddress = lib.mkIf isHome homeServiceAddress;
          };
          dns = confLib.mkDnsRecord {
            inherit proxyAddress4 proxyAddress6;
            serviceName = specificServiceName;
          };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit servicePort;
            expectedBodyRegex = ''"status":\s*"OK"'';
            path = "/rest/noauth/health";
            serviceName = specificServiceName;
          };
          networks = {
            ${homeProxyIf}.hosts = lib.mkIf isHome {
              ${config.node.name}.firewallRuleForNode.${homeWebProxy} = {
                allowedTCPPorts = [
                  servicePort
                  20000
                ];
                allowedUDPPorts = [
                  20000
                  21027
                ];
              };
            };
            ${webProxyIf}.hosts = lib.mkIf isProxied {
              ${config.node.name}.firewallRuleForNode.${webProxy} = {
                allowedTCPPorts = [
                  servicePort
                  22000
                ];
                allowedUDPPorts = [
                  20000
                  21027
                ];
              };
            };
          };
        };
        users = {
          users.${serviceUser} = {
            extraGroups = [ "users" ];
            group = serviceGroup;
            isSystemUser = true;
          };
          groups.${serviceGroup} = { };
        };
        services.${serviceName} = rec {
          enable = true;
          configDir =
            if config.swarselsystems.isMicroVM then
              "/var/lib/syncthing/.config/syncthing"
            else
              "${cfg.dataDir}/.config/${serviceName}";
          dataDir =
            if extraConfig ? dataDir then
              lib.mkForce extraConfig.dataDir
            else if config.swarselsystems.isMicroVM then
              "/storage/Documents/syncthing"
            else
              lib.mkDefault "/var/lib/${serviceName}";
          group = serviceGroup;
          guiAddress = "0.0.0.0:${builtins.toString servicePort}";
          openDefaultPorts = lib.mkIf (!isProxied) true; # opens ports TCP/UDP 22000 and UDP 21027 for discovery
          relay.enable = false;
          settings = {
            devices = baseDevices // (extraConfig.extraDevices or { });
            folders = {
              "Default Folder" = lib.mkForce {
                devices = syncDevices;
                id = "default";
                path = "${cfg.dataDir}/Sync";
                type = "receiveonly";
              };
              "Obsidian" = {
                devices = syncDevices;
                id = "yjvni-9eaa7";
                path = "${cfg.dataDir}/Obsidian";
                type = "receiveonly";
                versioning = {
                  params.keep = "5";
                  type = "simple";
                };
              };
              "Org" = {
                devices = syncDevices;
                id = "a7xnl-zjj3d";
                path = "${cfg.dataDir}/Org";
                type = "receiveonly";
                versioning = {
                  params.keep = "5";
                  type = "simple";
                };
              };
              "Vpn" = {
                devices = syncDevices;
                id = "hgp9s-fyq3p";
                path = "${cfg.dataDir}/Vpn";
                type = "receiveonly";
                versioning = {
                  params.keep = "5";
                  type = "simple";
                };
              };
            }
            // (extraConfig.extraFolders or { });
            urAccepted = -1;
          };
          user = serviceUser;
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = "/var/lib/${serviceName}";
              group = serviceGroup;
              user = serviceUser;
            }
          ];
        };
        nodes = lib.mkMerge [
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit serviceAddress serviceDomain servicePort;
              maxBody = 0;
              serviceName = specificServiceName;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain servicePort;
                extraConfig = nginxAccessRules;
                maxBody = 0;
                serviceAddress = homeServiceAddress;
                serviceName = specificServiceName;
              }
            );
          }
        ];

      };
    }

  ;
}
