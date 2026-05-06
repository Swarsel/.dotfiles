{ lib, config, pkgs, globals, ... }:
let
  inherit (config.swarselsystems) mainUser homeDir;
  syncthingConfig = globals.services.syncthing-summers-storage.extraConfig;
  devices = syncthingConfig.syncDevices;
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
        inherit (syncthingConfig) devices;
        folders = {
          "Default Folder" = lib.mkDefault {
            path = "${homeDir}/Sync";
            inherit devices;
            id = "default";
          };
          "Obsidian" = {
            path = "${homeDir}/Obsidian";
            inherit devices;
            id = "yjvni-9eaa7";
          };
          "Org" = {
            path = "${homeDir}/Org";
            inherit devices;
            id = "a7xnl-zjj3d";
          };
          "Vpn" = {
            path = "${homeDir}/Vpn";
            inherit devices;
            id = "hgp9s-fyq3p";
          };
        };
      };
    };
  };
}
