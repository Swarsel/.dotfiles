{ config, pkgs, lib, ... }:
{
  options.swarselsystems.modules.firefox = lib.mkEnableOption "firefox settings";
  config = lib.mkIf config.swarselsystems.modules.firefox {
    programs.firefox = {
      enable = true;
      package = pkgs.firefox; # uses overrides
      policies = {
        # CaptivePortal = false;
        AppAutoUpdate = false;
        BackgroundAppUpdate = false;
        DisableBuiltinPDFViewer = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFirefoxScreenshots = true;
        DisableTelemetry = true;
        DisableFirefoxAccounts = false;
        DisableProfileImport = true;
        DisableProfileRefresh = true;
        DisplayBookmarksToolbar = "always";
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        OfferToSaveLoginsDefault = false;
        PasswordManagerEnabled = false;
        DisableMasterPasswordCreation = true;
        ExtensionUpdate = false;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
          EmailTracking = true;
          # Exceptions = ["https://example.com"]
        };
        PDFjs = {
          Enabled = false;
          EnablePermissions = false;
        };
        Handlers = {
          mimeTypes."application/pdf".action = "saveToDisk";
        };
        extensions = {
          pdf = {
            action = "useHelperApp";
            ask = true;
            handlers = [
              {
                name = "GNOME Document Viewer";
                path = "${pkgs.evince}/bin/evince";
              }
            ];
          };
        };
        FirefoxHome = {
          Search = true;
          TopSites = true;
          SponsoredTopSites = false;
          Highlights = true;
          Pocket = false;
          SponsoredPocket = false;
          Snippets = false;
          Locked = true;
        };
        FirefoxSuggest = {
          WebSuggestions = false;
          SponsoredSuggestions = false;
          ImproveSuggest = false;
          Locked = true;
        };
        SanitizeOnShutdown = {
          Cache = true;
          Cookies = false;
          Downloads = true;
          FormData = true;
          History = false;
          Sessions = false;
          SiteSettings = false;
          OfflineApps = true;
          Locked = true;
        };
        SearchEngines = {
          PreventInstalls = true;
          Remove = [
            "Bing" # Fuck you
          ];
        };
        UserMessaging = {
          ExtensionRecommendations = false; # Don’t recommend extensions while the user is visiting web pages
          FeatureRecommendations = false; # Don’t recommend browser features
          Locked = true; # Prevent the user from changing user messaging preferences
          MoreFromMozilla = false; # Don’t show the “More from Mozilla” section in Preferences
          SkipOnboarding = true; # Don’t show onboarding messages on the new tab page
          UrlbarInterventions = false; # Don’t offer suggestions in the URL bar
          WhatsNew = false; # Remove the “What’s New” icon and menuitem
        };
        ExtensionSettings = {
          "3rdparty".Extensions = {
            # https://github.com/gorhill/uBlock/blob/master/platform/common/managed_storage.json
            "uBlock0@raymondhill.net".adminSettings = {
              userSettings = rec {
                uiTheme = "dark";
                uiAccentCustom = true;
                uiAccentCustom0 = "#0C8084";
                cloudStorageEnabled = lib.mkForce false;
                importedLists = [
                  "https://filters.adtidy.org/extension/ublock/filters/3.txt"
                  "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
                ];
                externalLists = lib.concatStringsSep "\n" importedLists;
              };
              selectedFilterLists = [
                "CZE-0"
                "adguard-generic"
                "adguard-annoyance"
                "adguard-social"
                "adguard-spyware-url"
                "easylist"
                "easyprivacy"
                "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
                "plowe-0"
                "ublock-abuse"
                "ublock-badware"
                "ublock-filters"
                "ublock-privacy"
                "ublock-quick-fixes"
                "ublock-unbreak"
                "urlhaus-1"
              ];
            };
          };

        };

      };

      profiles = {
        default = lib.recursiveUpdate
          {
            id = 0;
            isDefault = true;
            settings = {
              "browser.startup.homepage" = "https://outlook.office.com|https://satellite.vbc.ac.at|https://bitbucket.vbc.ac.at|https://github.com";
            };
          }
          config.swarselsystems.firefox;
      };
    };
  };
}
