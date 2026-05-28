{ lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "syncthing"; port = 8384; }) servicePort serviceName serviceUser serviceGroup serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;

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

    users.users.${serviceUser} = {
      extraGroups = [ "users" ];
      group = serviceGroup;
      isSystemUser = true;
    };

    users.groups.${serviceGroup} = { };

    # networking.firewall.allowedTCPPorts = [ servicePort ];

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy} = {
            allowedTCPPorts = [ servicePort 22000 ];
            allowedUDPPorts = [ 20000 21027 ];
          };
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeWebProxy} = {
            allowedTCPPorts = [ servicePort 20000 ];
            allowedUDPPorts = [ 20000 21027 ];
          };
        };
      };
      services.${specificServiceName} = {
        domain = lib.mkDefault config.repo.secrets.common.services.domains.${specificServiceName};
        inherit proxyAddress4 proxyAddress6 isHome serviceAddress;
        homeServiceAddress = lib.mkIf isHome homeServiceAddress;
        extraConfig.devices = baseDevices;
      };
      monitoring.http = confLib.mkHttpMonitoring { serviceName = specificServiceName; inherit servicePort; path = "/rest/noauth/health"; expectedBodyRegex = ''"status":\s*"OK"''; };
      dns = confLib.mkDnsRecord { serviceName = specificServiceName; inherit proxyAddress4 proxyAddress6; };
    };

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = "/var/lib/${serviceName}"; user = serviceUser; group = serviceGroup; }];
    };

    services.${serviceName} = rec {
      enable = true;
      user = serviceUser;
      group = serviceGroup;
      dataDir =
        if extraConfig ? dataDir then lib.mkForce extraConfig.dataDir
        else if config.swarselsystems.isMicroVM then "/storage/Documents/syncthing"
        else lib.mkDefault "/var/lib/${serviceName}";
      configDir = if config.swarselsystems.isMicroVM then "/var/lib/syncthing/.config/syncthing" else "${cfg.dataDir}/.config/${serviceName}";
      guiAddress = "0.0.0.0:${builtins.toString servicePort}";
      openDefaultPorts = lib.mkIf (!isProxied) true; # opens ports TCP/UDP 22000 and UDP 21027 for discovery
      relay.enable = false;
      settings = {
        urAccepted = -1;
        devices = baseDevices // (extraConfig.extraDevices or { });
        folders = {
          "Default Folder" = lib.mkForce {
            path = "${cfg.dataDir}/Sync";
            type = "receiveonly";
            devices = syncDevices;
            id = "default";
          };
          "Obsidian" = {
            path = "${cfg.dataDir}/Obsidian";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = syncDevices;
            id = "yjvni-9eaa7";
          };
          "Org" = {
            path = "${cfg.dataDir}/Org";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = syncDevices;
            id = "a7xnl-zjj3d";
          };
          "Vpn" = {
            path = "${cfg.dataDir}/Vpn";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = syncDevices;
            id = "hgp9s-fyq3p";
          };
        } // (extraConfig.extraFolders or { });
      };
    };

    nodes = {
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain; serviceName = specificServiceName; maxBody = 0; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain; serviceName = specificServiceName; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };
}
