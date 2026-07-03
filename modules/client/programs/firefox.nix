{
  flake.modules.homeManager.firefox =
    {
      pkgs,
      lib,
      vars,
      confLib,
      ...
    }:
    {
      config = {
        swarselsystems.enabledHomeModules = [ "firefox" ];

        xdg.desktopEntries.firefox_checker = {
          name = "Firefox (checker)";
          genericName = "Firefox checker";
          exec = "firefox -p checker";
          terminal = false;
          categories = [ "Application" ];
          icon = "firefox";
        };

        programs.zsh.sessionVariables = {
          MOZ_DISABLE_RDD_SANDBOX = "1";
        };

        programs.firefox = {
          enable = true;
          package = pkgs.firefox; # uses overrides
          configPath = ".mozilla/firefox";
          policies = vars.browserPolicies;

          profiles = {
            default = lib.recursiveUpdate {
              id = 0;
              isDefault = true;
              settings = {
                "browser.startup.homepage" = "https://lobste.rs";
              };
            } vars.firefox;
            checker = lib.recursiveUpdate {
              id = 5;
              settings = {
                "browser.startup.homepage" = confLib.getConfig.repo.secrets.common.checkerURLs;
              };
            } vars.firefox;
          };
        };
      };
    };
}
