{ lib, config, nixosConfig, ... }:
let
  inherit (nixosConfig.repo.secrets.common.mail) address1 address2 address3 address4 allMailAddresses;
  inherit (nixosConfig.repo.secrets.common) fullName;
in
{
  options.swarselsystems.modules.env = lib.mkEnableOption "env settings";
  config = lib.mkIf config.swarselsystems.modules.env {
    home.sessionVariables = {
      EDITOR = "e -w";
      DISPLAY = ":0";
      SWARSEL_LO_RES = config.swarselsystems.lowResolution;
      SWARSEL_HI_RES = config.swarselsystems.highResolution;
    };
    systemd.user.sessionVariables = {
      SWARSEL_MAIL1 = address1;
      SWARSEL_MAIL2 = address2;
      SWARSEL_MAIL3 = address3;
      SWARSEL_MAIL4 = address4;
      SWARSEL_FULLNAME = fullName;
      SWARSEL_MAIL_ALL = allMailAddresses;
    };
  };
}
