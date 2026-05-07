{ lib, config, pkgs, globals, ... }:
let
  inherit (config.swarselsystems) mainUser homeDir;
  inherit (globals.services."syncthing-${globals.general.homeSyncthingServer}".extraConfig) devices;
  syncDevices = builtins.attrNames devices;
  servicePort = 8384;
in
{
  config = {
    services.syncthing = {
      enable = true;
      systemService = true;
      guiAddress = "127.0.0.1:${builtins.toString servicePort}";
      package = pkgs.syncthing;
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
        inherit devices;
        folders = {
          "Default Folder" = lib.mkDefault {
            path = "${homeDir}/Sync";
            devices = syncDevices;
            id = "default";
          };
          "Obsidian" = {
            path = "${homeDir}/Obsidian";
            devices = syncDevices;
            id = "yjvni-9eaa7";
          };
          "Org" = {
            path = "${homeDir}/Org";
            devices = syncDevices;
            id = "a7xnl-zjj3d";
          };
          "Vpn" = {
            path = "${homeDir}/Vpn";
            devices = syncDevices;
            id = "hgp9s-fyq3p";
          };
        };
      };
    };
  };
}
