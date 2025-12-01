{ lib, config, confLib, globals, ... }:
let
  inherit (confLib.getConfig.repo.secrets.common.mail) address1 address2 address3 address4 allMailAddresses;
  inherit (confLib.getConfig.repo.secrets.common.calendar) source1 source1-name source2 source2-name source3 source3-name;
  inherit (confLib.getConfig.repo.secrets.common) fullName openrouterApi instaDomain sportDomain;
  inherit (config.swarselsystems) isPublic homeDir;

  DISPLAY = ":0";
in
{
  options.swarselmodules.env = lib.mkEnableOption "env settings";
  config = lib.mkIf config.swarselmodules.env {
    home.sessionVariables = {
      inherit DISPLAY;
      EDITOR = "e -w";
    } // (lib.optionalAttrs (!isPublic) { });
    systemd.user.sessionVariables = {
      DOCUMENT_DIR_PRIV = lib.mkForce "${homeDir}/Documents/Private";
      FLAKE = "${config.home.homeDirectory}/.dotfiles";
    } // lib.optionalAttrs (!isPublic) {
      SWARSEL_DOMAIN = globals.domains.main;
      SWARSEL_RSS_DOMAIN = globals.services.freshrss.domain;
      SWARSEL_MUSIC_DOMAIN = globals.services.navidrome.domain;
      SWARSEL_FILES_DOMAIN = globals.services.nextcloud.domain;
      SWARSEL_INSTA_DOMAIN = instaDomain;
      SWARSEL_SPORT_DOMAIN = sportDomain;
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
      SWARSEL_MAIL_ALL = lib.mkDefault allMailAddresses;
      GITHUB_NOTIFICATION_TOKEN_PATH = confLib.getConfig.sops.secrets.github-notifications-token.path;
      OPENROUTER_API_KEY = openrouterApi;
    };
  };
}
