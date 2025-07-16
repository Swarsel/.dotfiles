{ lib, config, ... }:
let
  inherit (config.repo.secrets.common) workHostName;

  servicePort = 8384;
  serviceUser = "syncthing";
  serviceGroup = serviceUser;
  serviceName = "syncthing";
  serviceDomain = config.repo.secrets.common.services.domains.syncthing1;

  cfg = config.services.${serviceName};
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    users.users.${serviceUser} = {
      extraGroups = [ "users" ];
      group = serviceGroup;
      isSystemUser = true;
    };

    users.groups.${serviceGroup} = { };

    networking.firewall.allowedTCPPorts = [ servicePort ];

    globals.services."${serviceName}-${config.networking.hostName}".domain = serviceDomain;

    services.${serviceName} = rec {
      enable = true;
      user = serviceUser;
      group = serviceGroup;
      dataDir = "/Vault/data/${serviceName}";
      configDir = "${cfg.dataDir}/.config/${serviceName}";
      guiAddress = "0.0.0.0:${builtins.toString servicePort}";
      openDefaultPorts = true; # opens ports TCP/UDP 22000 and UDP 21027 for discovery
      relay.enable = false;
      settings = {
        urAccepted = -1;
        devices = {
          "magicant" = {
            id = "VMWGEE2-4HDS2QO-KNQOVGN-LXLX6LA-666E4EK-ZBRYRRO-XFEX6FB-6E3XLQO";
          };
          "milkywell@oracle" = {
            id = "ETW6TST-NPK7MKZ-M4LXMHA-QUPQHDT-VTSHH5X-CR5EIN2-YU7E55F-MGT7DQB";
          };
          "${workHostName}" = {
            id = "YAPV4BV-I26WPTN-SIP32MV-SQP5TBZ-3CHMTCI-Z3D6EP2-MNDQGLP-53FT3AB";
          };
          "moonside@oracle" = {
            id = "VPCDZB6-MGVGQZD-Q6DIZW3-IZJRJTO-TCC3QUQ-2BNTL7P-AKE7FBO-N55UNQE";
          };
        };
        folders = {
          "Default Folder" = lib.mkForce {
            path = "${cfg.dataDir}/Sync";
            type = "receiveonly";
            versioning = null;
            devices = [ "milkywell@oracle" "magicant" "${workHostName}" "moonside@oracle" ];
            id = "default";
          };
          "Obsidian" = {
            path = "${cfg.dataDir}/Obsidian";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = [ "milkywell@oracle" "magicant" "${workHostName}" "moonside@oracle" ];
            id = "yjvni-9eaa7";
          };
          "Org" = {
            path = "${cfg.dataDir}/Org";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = [ "milkywell@oracle" "magicant" "${workHostName}" "moonside@oracle" ];
            id = "a7xnl-zjj3d";
          };
          "Vpn" = {
            path = "${cfg.dataDir}/Vpn";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = [ "milkywell@oracle" "magicant" "${workHostName}" "moonside@oracle" ];
            id = "hgp9s-fyq3p";
          };
          # "Documents" = {
          #   path = "${cfg.dataDir}/Documents";
          #   type = "receiveonly";
          #   versioning = {
          #     type = "simple";
          #     params.keep = "5";
          #   };
          #   devices = [ "magicant" "${workHostName}" "moonside@oracle" ];
          #   id = "hgr3d-pfu3w";
          # };
        };
      };
    };

    nodes.moonside.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "192.168.1.2:${builtins.toString servicePort}" = { };
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
              proxyPass = "http://${serviceName}";
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
