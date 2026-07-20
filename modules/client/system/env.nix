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
        inherit (confLib.getConfig.repo.secrets.common.mail)
          address1
          address2
          address3
          address4
          allMailAddresses
          ;
        inherit (confLib.getConfig.repo.secrets.common.calendar)
          source1
          source1-name
          source2
          source2-name
          source3
          source3-name
          ;
        inherit (confLib.getConfig.repo.secrets.common)
          fullName
          hfApi
          instaDomain
          openrouterApi
          sportDomain
          ;
        inherit (config.swarselsystems) homeDir isPublic;

        DISPLAY = ":0";
      in
      {
        config = {
          swarselsystems.enabledHomeModules = [ "env" ];
          home.sessionVariables = {
            inherit DISPLAY;
          }
          // (lib.optionalAttrs (!isPublic) { });
          systemd.user.sessionVariables = {
            DOCUMENT_DIR_PRIV = lib.mkForce "${homeDir}/Documents/Private";
            FLAKE = "${config.home.homeDirectory}/.dotfiles";
          }
          // lib.optionalAttrs (!isPublic) {
            GITHUB_NOTIFICATION_TOKEN_PATH = confLib.getConfig.sops.secrets.github-notifications-token.path;
            HF_TOKEN = hfApi;
            OPENROUTER_API_KEY = openrouterApi;
            SWARSEL_CAL1 = source1;
            SWARSEL_CAL1NAME = source1-name;
            SWARSEL_CAL2 = source2;
            SWARSEL_CAL2NAME = source2-name;
            SWARSEL_CAL3 = source3;
            SWARSEL_CAL3NAME = source3-name;
            SWARSEL_DOMAIN = globals.domains.main;
            SWARSEL_FILES_DOMAIN = globals.services.nextcloud.domain;
            SWARSEL_FULLNAME = fullName;
            SWARSEL_INSTA_DOMAIN = instaDomain;
            SWARSEL_MAIL1 = address1;
            SWARSEL_MAIL2 = address2;
            SWARSEL_MAIL3 = address3;
            SWARSEL_MAIL4 = address4;
            SWARSEL_MAIL_ALL = lib.mkDefault allMailAddresses;
            SWARSEL_MUSIC_DOMAIN = globals.services.navidrome.domain;
            SWARSEL_RSS_DOMAIN = globals.services.freshrss.domain;
            SWARSEL_SPORT_DOMAIN = sportDomain;
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
          }
          // (lib.optionalAttrs (!config.swarselsystems.isPublic) { });
          wordlist.enable = true;
        };
      };
  };
}
