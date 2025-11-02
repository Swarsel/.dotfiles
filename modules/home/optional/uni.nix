{ config, lib, nixosConfig ? config, ... }:
{
  options.swarselmodules.optional.uni = lib.mkEnableOption "optional uni settings";
  config = lib.mkIf config.swarselmodules.optional.uni
    {
      services.pizauth = {
        enable = true;
        accounts = {
          uni = {
            authUri = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize";
            tokenUri = "https://login.microsoftonline.com/common/oauth2/v2.0/token";
            clientId = "08162f7c-0fd2-4200-a84a-f25a4db0b584";
            clientSecret = "TxRBilcHdC6WGBee]fs?QR:SJ8nI[g82";
            scopes = [
              "https://outlook.office365.com/IMAP.AccessAsUser.All"
              "https://outlook.office365.com/SMTP.Send"
              "offline_access"
            ];
            loginHint = "${nixosConfig.repo.secrets.local.uni.mailAddress}";
          };
        };
      };
    };
}
