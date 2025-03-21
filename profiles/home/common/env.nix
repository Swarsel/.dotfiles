{ lib, config, nix-secrets, ... }:
let
  secretsDirectory = builtins.toString nix-secrets;
  leonMail = lib.swarselsystems.getSecret "${secretsDirectory}/mail/leon";
  nautilusMail = lib.swarselsystems.getSecret "${secretsDirectory}/mail/nautilus";
  mrswarselMail = lib.swarselsystems.getSecret "${secretsDirectory}/mail/mrswarsel";
  swarselMail = lib.swarselsystems.getSecret "${secretsDirectory}/mail/swarsel";
  fullName = lib.swarselsystems.getSecret "${secretsDirectory}/info/fullname";
  allMailAddresses = lib.swarselsystems.getSecret "${secretsDirectory}/mail/list";
in
{
  home.sessionVariables = {
    EDITOR = "e -w";
    DISPLAY = ":0";
    SWARSEL_LO_RES = config.swarselsystems.lowResolution;
    SWARSEL_HI_RES = config.swarselsystems.highResolution;
    SWARSEL_LEON_MAIL = leonMail;
    SWARSEL_NAUTILUS_MAIL = nautilusMail;
    SWARSEL_MRSWARSEL_MAIL = mrswarselMail;
    SWARSEL_SWARSEL_MAIL = swarselMail;
    SWARSEL_FULLNAME = fullName;
    SWARSEL_MAIL_ALL = allMailAddresses;

  };
}
