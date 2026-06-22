{
  flake.modules.homeManager.anki =
    {
      pkgs,
      globals,
      confLib,
      ...
    }:
    {
      config = {
        swarselsystems.enabledHomeModules = [ "anki" ];

        swarselsystems.homeSopsSecrets = {
          anki-user = { };
          anki-pw = { };
        };

        programs.anki = {
          enable = true;
          package = pkgs.anki;
          hideBottomBar = true;
          hideBottomBarMode = "always";
          hideTopBar = true;
          hideTopBarMode = "always";
          reduceMotion = true;
          spacebarRatesCard = true;
          # videoDriver = "opengl";
          profiles."User 1".sync = {
            autoSync = false; # sync on profile close will delay system shutdown
            syncMedia = true;
            autoSyncMediaMinutes = 5;
            url = "https://${globals.services.ankisync.domain}";
            usernameFile = confLib.getConfig.sops.secrets.anki-user.path;
            # this is not the password but the syncKey
            # get it by logging in or out, saving preferences and then
            # show details on the "settings wont be saved" dialog
            keyFile = confLib.getConfig.sops.secrets.anki-pw.path;
          };
          addons =
            let
              minimize-to-tray = pkgs.anki-utils.buildAnkiAddon (finalAttrs: {
                pname = "minimize-to-tray";
                version = "2.0.1";
                src = pkgs.fetchFromGitHub {
                  owner = "simgunz";
                  repo = "anki21-addons_minimize-to-tray";
                  rev = finalAttrs.version;
                  sparseCheckout = [ "src" ];
                  hash = "sha256-xmvbIOfi9K0yEUtUNKtuvv2Vmqrkaa4Jie6J1s+FuqY=";
                };
                sourceRoot = "${finalAttrs.src.name}/src";
              });
            in
            [
              (minimize-to-tray.withConfig {
                config = {
                  hide_on_startup = "true";
                };
              })
            ];
        };
      };
    };
}
