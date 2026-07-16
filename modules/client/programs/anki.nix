{
  flake.modules.homeManager.anki =
    {
      pkgs,
      confLib,
      globals,
      ...
    }:
    {
      config = {
        swarselsystems = {
          enabledHomeModules = [ "anki" ];
          homeSopsSecrets = {
            anki-pw = { };
            anki-user = { };
          };
        };
        programs.anki = {
          enable = true;
          package = pkgs.anki;
          addons =
            let
              minimize-to-tray = pkgs.anki-utils.buildAnkiAddon (finalAttrs: {
                pname = "minimize-to-tray";
                sourceRoot = "${finalAttrs.src.name}/src";
                src = pkgs.fetchFromGitHub {
                  hash = "sha256-xmvbIOfi9K0yEUtUNKtuvv2Vmqrkaa4Jie6J1s+FuqY=";
                  owner = "simgunz";
                  repo = "anki21-addons_minimize-to-tray";
                  rev = finalAttrs.version;
                  sparseCheckout = [ "src" ];
                };
                version = "2.0.1";
              });
            in
            [
              (minimize-to-tray.withConfig {
                config = {
                  hide_on_startup = "true";
                };
              })
            ];
          hideBottomBar = true;
          hideBottomBarMode = "always";
          hideTopBar = true;
          hideTopBarMode = "always";
          # videoDriver = "opengl";
          profiles."User 1".sync = {
            autoSync = false; # sync on profile close will delay system shutdown
            autoSyncMediaMinutes = 5;
            # this is not the password but the syncKey
            # get it by logging in or out, saving preferences and then
            # show details on the "settings wont be saved" dialog
            keyFile = confLib.getConfig.sops.secrets.anki-pw.path;
            syncMedia = true;
            url = "https://${globals.services.ankisync.domain}";
            usernameFile = confLib.getConfig.sops.secrets.anki-user.path;
          };
          reduceMotion = true;
          spacebarRatesCard = true;
        };
      };
    };
}
