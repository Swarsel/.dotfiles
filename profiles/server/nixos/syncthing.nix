{ lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.syncthing {

    users.users.syncthing = {
      extraGroups = [ "users" ];
      group = "syncthing";
      isSystemUser = true;
    };

    users.groups.syncthing = { };

    services.syncthing = {
      enable = true;
      user = "swarsel";
      dataDir = "/Vault/data/syncthing";
      configDir = "/Vault/apps/syncthing";
      guiAddress = "0.0.0.0:8384";
      openDefaultPorts = true;
      relay.enable = false;
      settings = {
        urAccepted = -1;
        devices = {
          "magicant" = {
            id = "VMWGEE2-4HDS2QO-KNQOVGN-LXLX6LA-666E4EK-ZBRYRRO-XFEX6FB-6E3XLQO";
          };
          "sync (@oracle)" = {
            id = "ETW6TST-NPK7MKZ-M4LXMHA-QUPQHDT-VTSHH5X-CR5EIN2-YU7E55F-MGT7DQB";
          };
          "nbl-imba-2" = {
            id = "YAPV4BV-I26WPTN-SIP32MV-SQP5TBZ-3CHMTCI-Z3D6EP2-MNDQGLP-53FT3AB";
          };
        };
        folders = {
          "Default Folder" = {
            path = "/Vault/data/syncthing/Sync";
            type = "receiveonly";
            versioning = null;
            devices = [ "sync (@oracle)" "magicant" "nbl-imba-2" ];
            id = "default";
          };
          "Obsidian" = {
            path = "/Vault/data/syncthing/Obsidian";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = [ "sync (@oracle)" "magicant" "nbl-imba-2" ];
            id = "yjvni-9eaa7";
          };
          "Org" = {
            path = "/Vault/data/syncthing/Org";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = [ "sync (@oracle)" "magicant" "nbl-imba-2" ];
            id = "a7xnl-zjj3d";
          };
          "Vpn" = {
            path = "/Vault/data/syncthing/Vpn";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = [ "sync (@oracle)" "magicant" "nbl-imba-2" ];
            id = "hgp9s-fyq3p";
          };
          "Documents" = {
            path = "/Vault/data/syncthing/Documents";
            type = "receiveonly";
            versioning = {
              type = "simple";
              params.keep = "5";
            };
            devices = [ "magicant" "nbl-imba-2" ];
            id = "hgr3d-pfu3w";
          };
          ".elfeed" = {
            path = "/Vault/data/syncthing/.elfeed";
            devices = [ "sync (@oracle)" "magicant" "nbl-imba-2" ];
            id = "h7xbs-fs9v1";
          };
        };
      };
    };

    services.nginx = {
      virtualHosts = {
        "storync.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://localhost:8384";
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