{ self, lib, pkgs, ... }:
let
  lock-false = {
    Value = false;
    Status = "locked";
  };
  lock-true = {
    Value = true;
    Status = "locked";
  };
in
{
  options.swarselsystems = {
    firefox = lib.mkOption {
      type = lib.types.attrs;
      default = {
        isDefault = false;
        userChrome = builtins.readFile "${self}/programs/firefox/chrome/userChrome.css";
        extensions = {
          packages = with pkgs.nur.repos.rycee.firefox-addons; [
            tridactyl
            tampermonkey
            sidebery
            browserpass
            clearurls
            darkreader
            enhancer-for-youtube
            istilldontcareaboutcookies
            translate-web-pages
            ublock-origin
            reddit-enhancement-suite
            sponsorblock
            web-archives
            onepassword-password-manager
            single-file
            widegithub
            enhanced-github
            unpaywall
            don-t-fuck-with-paste
            plasma-integration
            (buildFirefoxXpiAddon {
              pname = "shortkeys";
              version = "4.0.2";
              addonId = "Shortkeys@Shortkeys.com";
              url = "https://addons.mozilla.org/firefox/downloads/file/3673761/shortkeys-4.0.2.xpi";
              sha256 = "c6fe12efdd7a871787ac4526eea79ecc1acda8a99724aa2a2a55c88a9acf467c";
              meta = with lib;
                {
                  description = "Easily customizable custom keyboard shortcuts for Firefox. To configure this addon go to Addons (ctrl+shift+a) ->Shortkeys ->Options. Report issues here (please specify that the issue is found in Firefox): https://github.com/mikecrittenden/shortkeys";
                  mozPermissions = [
                    "tabs"
                    "downloads"
                    "clipboardWrite"
                    "browsingData"
                    "storage"
                    "bookmarks"
                    "sessions"
                    "<all_urls>"
                  ];
                  platforms = platforms.all;
                };
            })
          ];
        };

        settings =
          {
            "extensions.autoDisableScopes" = 0;
            "browser.bookmarks.showMobileBookmarks" = lock-true;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = lock-true;
            "browser.search.suggest.enabled" = lock-false;
            "browser.search.suggest.enabled.private" = lock-false;
            "browser.urlbar.suggest.searches" = lock-false;
            "browser.urlbar.showSearchSuggestionsFirst" = lock-false;
            "browser.topsites.contile.enabled" = lock-false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
            "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
            "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
            "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
            "browser.newtabpage.activity-stream.showSponsored" = lock-false;
            "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
          };

        search = {
          default = "Kagi";
          privateDefault = "Kagi";
          engines = {
            "Kagi" = {
              urls = [{
                template = "https://kagi.com/search";
                params = [
                  { name = "q"; value = "{searchTerms}"; }
                ];
              }];
              iconUpdateURL = "https://kagi.com/favicon.ico";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "@k" ];
            };

            "Nix Packages" = {
              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                  { name = "type"; value = "packages"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };

            "NixOS Wiki" = {
              urls = [{
                template = "https://nixos.wiki/index.php?search={searchTerms}";
              }];
              iconUpdateURL = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "@nw" ];
            };

            "NixOS Options" = {
              urls = [{
                template = "https://search.nixos.org/options";
                params = [
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];

              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@no" ];
            };

            "Home Manager Options" = {
              urls = [{
                template = "https://home-manager-options.extranix.com/";
                params = [
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];

              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@hm" "@ho" "@hmo" ];
            };

            "Google".metaData.alias = "@g";
          };
          force = true; # this is required because otherwise the search.json.mozlz4 symlink gets replaced on every firefox restart
        };
      };
    };
  };

}
