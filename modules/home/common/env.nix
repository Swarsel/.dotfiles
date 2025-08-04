{ lib, config, globals, nixosConfig ? config, ... }:
let
  inherit (nixosConfig.repo.secrets.common.mail) address1 address2 address3 address4 allMailAddresses;
  inherit (nixosConfig.repo.secrets.common.calendar) source1 source1-name source2 source2-name source3 source3-name;
  inherit (nixosConfig.repo.secrets.common) fullName;
  inherit (config.swarselsystems) isPublic;
  crocDomain = globals.services.croc.domain;
in
{
  options.swarselmodules.env = lib.mkEnableOption "env settings";
  config = lib.mkIf config.swarselmodules.env {
    home.sessionVariables = {
      EDITOR = "e -w";
      DISPLAY = ":0";
      SWARSEL_LO_RES = config.swarselsystems.lowResolution;
      SWARSEL_HI_RES = config.swarselsystems.highResolution;
    } // (lib.optionalAttrs (!isPublic) {
      CROC_RELAY = crocDomain;
      GITHUB_NOTIFICATION_TOKEN_PATH = nixosConfig.sops.secrets.github-notifications-token.path;
    });
    systemd.user.sessionVariables = lib.mkIf (!isPublic) {
      SWARSEL_MAIL1 = address1;
      SWARSEL_MAIL2 = address2;
      SWARSEL_MAIL3 = address3;
      SWARSEL_MAIL4 = address4;
      SWARSEL_CAL1 = source1;
      SWARSEL_CAL1NAME = source1-name;
      SWARSEL_CAL2 = source2;
      SWARSEL_CAL2NAME = source2-name;
      SWARSEL_CAL3 = source3;
      SWARSEL_CAL3NAME = source3-name;
      SWARSEL_FULLNAME = fullName;
      SWARSEL_MAIL_ALL = allMailAddresses;
    };
  };
}
