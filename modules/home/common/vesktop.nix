{ lib, pkgs, config, ... }:
let
  moduleName = "vesktop";
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "enable ${moduleName} and settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    programs.${moduleName} = {
      enable = true;
      package = pkgs.stable.vesktop;
      settings = {
        appBadge = false;
        arRPC = false;
        checkUpdates = false;
        customTitleBar = false;
        disableMinSize = true;
        minimizeToTray = true;
        tray = true;
        staticTitle = true;
        hardwareAcceleration = true;
        discordBranch = "stable";
      };
      vencord = {
        useSystem = true;
        settings = {
          autoUpdate = false;
          autoUpdateNotification = false;
          enableReactDevtools = false;
          frameless = false;
          transparent = false;
          winCtrlQ = false;
          notifyAboutUpdates = false;
          useQuickCss = true;
          disableMinSize = true;
          winNativeTitleBar = false;
          plugins = {
            MessageLogger = {
              enabled = true;
              ignoreSelf = true;
            };
            ChatInputButtonAPI = {
              enabled = false;
            };
            CommandsAPI = {
              enabled = true;
            };
            MemberListDecoratorsAPI = {
              enabled = false;
            };
            MessageAccessoriesAPI = {
              enabled = true;
            };
            MessageDecorationsAPI = {
              enabled = false;
            };
            MessageEventsAPI = {
              enabled = false;
            };
            MessagePopoverAPI = {
              enabled = false;
            };
            MessageUpdaterAPI = {
              enabled = false;
            };
            ServerListAPI = {
              enabled = false;
            };
            UserSettingsAPI = {
              enabled = true;
            };
            FakeNitro = {
              enabled = true;
            };
          };
        };
      };
    };
  };

}
