{ lib, config, pkgs, ... }:
let
  inherit (config.swarselsystems) mainUser homeDir;
in
{
  options.swarselmodules.syncthing = lib.mkEnableOption "syncthing config";
  config = lib.mkIf config.swarselmodules.syncthing {
    services.syncthing = {
      enable = true;
      package = pkgs.stable.syncthing;
      user = mainUser;
      dataDir = homeDir;
      configDir = "${homeDir}/.config/syncthing";
      openDefaultPorts = true;
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        options = {
          urAccepted = -1;
        };
        devices = {
          "magicant" = {
            id = "VMWGEE2-4HDS2QO-KNQOVGN-LXLX6LA-666E4EK-ZBRYRRO-XFEX6FB-6E3XLQO";
          };
          "sync@oracle" = {
            id = "ETW6TST-NPK7MKZ-M4LXMHA-QUPQHDT-VTSHH5X-CR5EIN2-YU7E55F-MGT7DQB";
          };
          "winters" = {
            id = "O7RWDMD-AEAHPP7-7TAVLKZ-BSWNBTU-2VA44MS-EYGUNBB-SLHKB3C-ZSLMOAA";
          };
          "moonside@oracle" = {
            id = "VPCDZB6-MGVGQZD-Q6DIZW3-IZJRJTO-TCC3QUQ-2BNTL7P-AKE7FBO-N55UNQE";
          };
        };
        folders = {
          "Default Folder" = lib.mkDefault {
            path = "${homeDir}/Sync";
            devices = [ "sync@oracle" "magicant" "winters" "moonside@oracle" ];
            id = "default";
          };
          "Obsidian" = {
            path = "${homeDir}/Nextcloud/Obsidian";
            devices = [ "sync@oracle" "magicant" "winters" "moonside@oracle" ];
            id = "yjvni-9eaa7";
          };
          "Org" = {
            path = "${homeDir}/Nextcloud/Org";
            devices = [ "sync@oracle" "magicant" "winters" "moonside@oracle" ];
            id = "a7xnl-zjj3d";
          };
          "Vpn" = {
            path = "${homeDir}/Vpn";
            devices = [ "sync@oracle" "magicant" "winters" "moonside@oracle" ];
            id = "hgp9s-fyq3p";
          };
        };
      };
    };
  };
}
