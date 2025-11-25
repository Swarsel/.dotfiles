{ lib, config, globals, dns, confLib, ... }:
let
  inherit (config.swarselsystems.syncthing) serviceDomain;
  inherit (confLib.gen { name = "syncthing"; port = 8384; }) servicePort serviceName serviceUser serviceGroup serviceAddress serviceProxy proxyAddress4 proxyAddress6;

  specificServiceName = "${serviceName}-${config.node.name}";

  cfg = config.services.${serviceName};
  devices = config.swarselsystems.syncthing.syncDevices;
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";

    swarselsystems.syncthing = {
      serviceDomain = lib.mkOption {
        type = lib.types.str;
        default = config.repo.secrets.common.services.domains.syncthing1;
      };
      syncDevices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "magicant" "winters" "pyramid" "moonside@oracle" ];
      };
      devices = lib.mkOption {
        type = lib.types.attrs;
        default = {
          "magicant" = {
            id = "VMWGEE2-4HDS2QO-KNQOVGN-LXLX6LA-666E4EK-ZBRYRRO-XFEX6FB-6E3XLQO";
          };
          "winters" = {
            id = "O7RWDMD-AEAHPP7-7TAVLKZ-BSWNBTU-2VA44MS-EYGUNBB-SLHKB3C-ZSLMOAA";
          };
          "moonside@oracle" = {
            id = "VPCDZB6-MGVGQZD-Q6DIZW3-IZJRJTO-TCC3QUQ-2BNTL7P-AKE7FBO-N55UNQE";
          };
          "pyramid" = {
            id = "YAPV4BV-I26WPTN-SIP32MV-SQP5TBZ-3CHMTCI-Z3D6EP2-MNDQGLP-53FT3AB";
          };
        };
      };
    };
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    swarselsystems.server.dns.${globals.services.${specificServiceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${specificServiceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    users.users.${serviceUser} = {
      extraGroups = [ "users" ];
      group = serviceGroup;
      isSystemUser = true;
    };

    users.groups.${serviceGroup} = { };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    globals.services.${specificServiceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
    };

    services.${serviceName} = rec {
      enable = true;
      user = serviceUser;
      group = serviceGroup;
      dataDir = lib.mkDefault "/Vault/data/${serviceName}";
      configDir = "${cfg.dataDir}/.config/${serviceName}";
      guiAddress = "0.0.0.0:${builtins.toString servicePort}";
      openDefaultPorts = true; # opens ports TCP/UDP 22000 and UDP 21027 for discovery
      relay.enable = false;
      settings = {
        urAccepted = -1;
        inherit (config.swarselsystems.syncthing) devices;
        folders = {
          "Default Folder" = lib.mkForce {
            path = "${cfg.dataDir}/Sync";
            type = "receiveonly";
            versioning = null;
            inherit devices;
            id = "default";
          };
          "Obsidian" = {
            path = "${cfg.dataDir}/Obsidian";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            inherit devices;
            id = "yjvni-9eaa7";
          };
          "Org" = {
            path = "${cfg.dataDir}/Org";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            inherit devices;
            id = "a7xnl-zjj3d";
          };
          "Vpn" = {
            path = "${cfg.dataDir}/Vpn";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            inherit devices;
            id = "hgp9s-fyq3p";
          };
        };
      };
    };

    nodes.${serviceProxy}.services.nginx = {
      upstreams = {
        ${specificServiceName} = {
          servers = {
            "${serviceAddress}:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://${specificServiceName}";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };
      };
    };
  };
}
