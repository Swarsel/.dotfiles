{ config, ... }:
let
  fmods = config.flake.modules;
in
{
  flake.modules = {
    homeManager.uni = { confLib, ... }: {
      config = {
        services.pizauth = {
          enable = true;
          accounts = {
            uni = {
              authUri = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize";
              clientId = "08162f7c-0fd2-4200-a84a-f25a4db0b584";
              clientSecret = "TxRBilcHdC6WGBee]fs?QR:SJ8nI[g82";
              loginHint = "${confLib.getConfig.repo.secrets.local.uni.mailAddress}";
              scopes = [
                "https://outlook.office365.com/IMAP.AccessAsUser.All"
                "https://outlook.office365.com/SMTP.Send"
                "offline_access"
              ];
              tokenUri = "https://login.microsoftonline.com/common/oauth2/v2.0/token";
            };
          };
        };
      };
    };
    nixos.uni =
      {
        config,
        lib,
        withHomeManager,
        ...
      }:
      {
        config =
          { }
          // lib.optionalAttrs withHomeManager {

            home-manager.users."${config.swarselsystems.mainUser}" = {
              imports = [
                fmods.homeManager.work
              ];
            };
          };
      };
  };
}
