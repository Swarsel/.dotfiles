{ lib, config, ... }:
let
  inherit (config.swarselsystems) mainUser homeDir;
in
{
  options.swarselsystems.modules.syncthing = lib.mkEnableOption "syncthing config";
  config = lib.mkIf config.swarselsystems.modules.syncthing {
    services.syncthing = {
      enable = true;
      user = mainUser;
      dataDir = homeDir;
      configDir = "${homeDir}/.config/syncthing";
      openDefaultPorts = true;
      settings = {
        devices = {
          "magicant" = {
            id = "VMWGEE2-4HDS2QO-KNQOVGN-LXLX6LA-666E4EK-ZBRYRRO-XFEX6FB-6E3XLQO";
          };
          "sync (@oracle)" = {
            id = "ETW6TST-NPK7MKZ-M4LXMHA-QUPQHDT-VTSHH5X-CR5EIN2-YU7E55F-MGT7DQB";
          };
          "winters" = {
            id = "O7RWDMD-AEAHPP7-7TAVLKZ-BSWNBTU-2VA44MS-EYGUNBB-SLHKB3C-ZSLMOAA";
          };
        };
        folders = {
          "Default Folder" = lib.mkDefault {
            path = "${homeDir}/Sync";
            devices = [ "sync (@oracle)" "magicant" "winters" ];
            id = "default";
          };
          "Obsidian" = {
            path = "${homeDir}/Nextcloud/Obsidian";
            devices = [ "sync (@oracle)" "magicant" "winters" ];
            id = "yjvni-9eaa7";
          };
          "Org" = {
            path = "${homeDir}/Nextcloud/Org";
            devices = [ "sync (@oracle)" "magicant" "winters" ];
            id = "a7xnl-zjj3d";
          };
          "Vpn" = {
            path = "${homeDir}/Vpn";
            devices = [ "sync (@oracle)" "magicant" "winters" ];
            id = "hgp9s-fyq3p";
          };
          ".elfeed" = {
            path = "${homeDir}/.elfeed";
            devices = [ "sync (@oracle)" "magicant" "winters" ];
            id = "h7xbs-fs9v1";
          };
        };
      };
    };
  };
}
