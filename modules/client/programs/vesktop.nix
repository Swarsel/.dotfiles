{
  flake.modules.homeManager.vesktop =
    { pkgs, ... }:
    let
      moduleName = "vesktop";
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "vesktop" ];
        programs.${moduleName} = {
          enable = true;
          package = pkgs.vesktop;
          settings = {
            appBadge = false;
            arRPC = false;
            checkUpdates = false;
            customTitleBar = false;
            disableMinSize = true;
            discordBranch = "stable";
            hardwareAcceleration = true;
            minimizeToTray = true;
            staticTitle = true;
            tray = true;
          };
          vencord = {
            settings = {
              autoUpdate = false;
              autoUpdateNotification = false;
              disableMinSize = true;
              enableReactDevtools = false;
              frameless = false;
              notifyAboutUpdates = false;
              plugins = {
                ChatInputButtonAPI = {
                  enabled = false;
                };
                CommandsAPI = {
                  enabled = true;
                };
                FakeNitro = {
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
                MessageLogger = {
                  enabled = true;
                  ignoreSelf = true;
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
              };
              transparent = false;
              useQuickCss = true;
              winCtrlQ = false;
              winNativeTitleBar = false;
            };
            useSystem = true;
          };
        };
      };
    };
}
