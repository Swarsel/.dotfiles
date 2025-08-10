{ self, lib, pkgs, ... }:
{
  _module.args = {
    vars = {
      stylix = {
        polarity = "dark";
        opacity.popups = 0.5;
        cursor = {
          package = pkgs.banana-cursor;
          # package = pkgs.capitaine-cursors;
          name = "Banana";
          # name = "capitaine-cursors";
          size = 16;
        };
        fonts = {
          sizes = {
            terminal = 10;
            applications = 11;
          };
          serif = {
            # package = (pkgs.nerdfonts.override { fonts = [ "FiraMono" "FiraCode"]; });
            package = pkgs.cantarell-fonts;
            # package = pkgs.montserrat;
            name = "Cantarell";
            # name = "FiraCode Nerd Font Propo";
            # name = "Montserrat";
          };
          sansSerif = {
            # package = (pkgs.nerdfonts.override { fonts = [ "FiraMono" "FiraCode"]; });
            package = pkgs.cantarell-fonts;
            # package = pkgs.montserrat;
            name = "Cantarell";
            # name = "FiraCode Nerd Font Propo";
            # name = "Montserrat";
          };
          monospace = {
            package = pkgs.nerd-fonts.fira-mono; # has overrides
            name = "FiraCode Nerd Font Mono";
          };
          emoji = {
            package = pkgs.noto-fonts-emoji;
            name = "Noto Color Emoji";
          };
        };
      };

      stylixHomeTargets = {
        emacs.enable = false;
        waybar.enable = false;
        sway.useWallpaper = false;
        spicetify.enable = true;
        firefox.profileNames = [ "default" ];
      };

      firefox = {
        userChrome = builtins.readFile "${self}/files/firefox/chrome/userChrome.css";
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
            noscript

            # configure a shortcut 'ctrl+shift+c' with behaviour 'do nothing' in order to disable the dev console shortcut
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
            "browser.bookmarks.showMobileBookmarks" = true;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "browser.search.suggest.enabled" = false;
            "browser.search.suggest.enabled.private" = false;
            "browser.urlbar.suggest.searches" = false;
            "browser.urlbar.showSearchSuggestionsFirst" = false;
            "browser.topsites.contile.enabled" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
            "browser.newtabpage.activity-stream.feeds.snippets" = false;
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.system.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          };

        search = {
          # default = "Kagi";
          default = "google";
          # privateDefault = "Kagi";
          privateDefault = "google";
          engines = {
            "Kagi" = {
              urls = [{
                template = "https://kagi.com/search";
                params = [
                  { name = "q"; value = "{searchTerms}"; }
                ];
              }];
              icon = "https://kagi.com/favicon.ico";
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
              icon = "https://nixos.wiki/favicon.png";
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

            "Confluence search" = {
              urls = [{
                template = "https://vbc.atlassian.net/wiki/search";
                params = [
                  { name = "text"; value = "{searchTerms}"; }
                ];
              }];

              definedAliases = [ "@c" "@cf" "@confluence" ];
            };

            "Jira search" = {
              urls = [{
                template = "https://vbc.atlassian.net/issues/";
                params = [
                  { name = "jql"; value = "textfields ~ \"{searchTerms}*\"&wildcardFlag=true"; }
                ];
              }];

              definedAliases = [ "@j" "@jire" ];
            };

            "google".metaData.alias = "@g";
          };
          force = true; # this is required because otherwise the search.json.mozlz4 symlink gets replaced on every firefox restart
        };
      };
    };
  };
}
