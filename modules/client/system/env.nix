{
  flake.modules = {
    homeManager.env =
      {
        config,
        lib,
        confLib,
        globals,
        ...
      }:
      let
        inherit (confLib.getConfig.repo.secrets) common;
        inherit (common) calendar mail;
        inherit (config.swarselsystems) homeDir isPublic;
      in
      {
        config = {
          swarselsystems.enabledHomeModules = [ "env" ];
          home.sessionVariables.DISPLAY = ":0";
          systemd.user.sessionVariables = {
            DOCUMENT_DIR_PRIV = "${homeDir}/Documents/Private";
            FLAKE = "${homeDir}/.dotfiles";
          }
          // lib.optionalAttrs (!isPublic) {
            HF_TOKEN = common.hfApi;
            OPENROUTER_API_KEY = common.openrouterApi;
            SWARSEL_CAL1 = calendar.source1;
            SWARSEL_CAL1NAME = calendar.source1-name;
            SWARSEL_CAL2 = calendar.source2;
            SWARSEL_CAL2NAME = calendar.source2-name;
            SWARSEL_CAL3 = calendar.source3;
            SWARSEL_CAL3NAME = calendar.source3-name;
            SWARSEL_DOMAIN = globals.domains.main;
            SWARSEL_FILES_DOMAIN = globals.services.nextcloud.domain;
            SWARSEL_FULLNAME = common.fullName;
            SWARSEL_INSTA_DOMAIN = common.instaDomain;
            SWARSEL_MAIL1 = mail.address1;
            SWARSEL_MAIL2 = mail.address2;
            SWARSEL_MAIL3 = mail.address3;
            SWARSEL_MAIL4 = mail.address4;
            SWARSEL_MAIL_ALL = lib.mkDefault mail.allMailAddresses;
            SWARSEL_MUSIC_DOMAIN = globals.services.navidrome.domain;
            SWARSEL_RSS_DOMAIN = globals.services.freshrss.domain;
            SWARSEL_SPORT_DOMAIN = common.sportDomain;
          };
        };
      };
    nixos.env =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        config.environment = {
          sessionVariables = {
            GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (
              with pkgs.gst_all_1;
              [
                gst-plugins-good
                gst-plugins-bad
                gst-plugins-ugly
                gst-libav
              ]
            );
            NIXOS_OZONE_WL = "1";
            SWARSEL_HI_RES = config.swarselsystems.highResolution;
            SWARSEL_LO_RES = config.swarselsystems.lowResolution;
          };
          wordlist.enable = true;
        };
      };
  };
}
