{
  flake.modules.generic.vars =
    {
      self,
      config,
      lib,
      pkgs,
      globals,
      ...
    }:
    {
      _module.args = {
        vars = rec {
          waylandSessionVariables = {
            ANKI_WAYLAND = "1";
            MOZ_ENABLE_WAYLAND = "1";
            MOZ_WEBRENDER = "1";
            NIXOS_OZONE_WL = "1";
            OBSIDIAN_USE_WAYLAND = "1";
            QT_QPA_PLATFORM = "wayland-egl";
            QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
            SDL_VIDEODRIVER = "wayland";
            _JAVA_AWT_WM_NONREPARENTING = "1";
          };

          waylandExports =
            let
              renderedWaylandExports = map (key: "export ${key}=${waylandSessionVariables.${key}};") (
                builtins.attrNames waylandSessionVariables
              );
            in
            builtins.concatStringsSep "\n" renderedWaylandExports;

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
                # package = pkgs.cantarell-fonts;
                # package = pkgs.montserrat;
                # name = "Cantarell";
                package = pkgs.iosevka-bin.override { variant = "Aile"; };
                name = "Iosevka Aile";
                # name = "FiraCode Nerd Font Propo";
                # name = "Montserrat";
              };
              sansSerif = {
                # package = (pkgs.nerdfonts.override { fonts = [ "FiraMono" "FiraCode"]; });
                # package = pkgs.cantarell-fonts;
                # package = pkgs.montserrat;
                # name = "Cantarell";
                package = pkgs.iosevka-bin.override { variant = "Aile"; };
                name = "Iosevka Aile";
                # name = "FiraCode Nerd Font Propo";
                # name = "Montserrat";
              };
              monospace = {
                package = pkgs.nerd-fonts.fira-code; # has overrides
                name = "FiraCode Nerd Font";
              };
              emoji = {
                package = pkgs.noto-fonts-color-emoji;
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

          browserPolicies = {
            # CaptivePortal = false;
            AppAutoUpdate = false;
            BackgroundAppUpdate = false;
            DisableBuiltinPDFViewer = true;
            DisableFirefoxStudies = true;
            DisableFirefoxScreenshots = true;
            DisableTelemetry = true;
            DisableFirefoxAccounts = false;
            DisableProfileImport = true;
            DisableProfileRefresh = true;
            DisplayBookmarksToolbar = "always";
            DontCheckDefaultBrowser = true;
            NoDefaultBookmarks = true;
            OfferToSaveLogins = false;
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
              extensions.pdf = {
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
          };

          firefox = rec {
            userChrome = builtins.readFile "${self}/files/firefox/chrome/userChrome.css";
            extensions = {
              packages = with pkgs.nur.repos.rycee.firefox-addons; [
                tridactyl
                tampermonkey
                browserpass
                clearurls
                darkreader
                istilldontcareaboutcookies
                translate-web-pages
                ublock-origin
                reddit-enhancement-suite
                sponsorblock
                web-archives
                onepassword-password-manager
                single-file
                stylus
                widegithub
                enhanced-github
                don-t-fuck-with-paste
                redirector
              ];

              settings =
                lib.optionalAttrs config.programs.password-store.enable {
                  "browserpass@maximbaz.com" = {
                    force = true;
                    settings.stores.default = {
                      id = "default";
                      name = "default";
                      path = config.programs.password-store.settings.PASSWORD_STORE_DIR;
                    };
                  };
                }
                // {
                  "uBlock0@raymondhill.net" = {
                    force = true;
                    settings = rec {
                      uiTheme = "dark";
                      uiAccentCustom = true;
                      uiAccentCustom0 = config.lib.stylix.colors.withHashtag.base0C;
                      cloudStorageEnabled = false;
                      importedLists = [
                        "https://filters.adtidy.org/extension/ublock/filters/3.txt"
                        "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
                      ];
                      externalLists = lib.concatStringsSep "\n" importedLists;
                      selectedFilterLists = [
                        "user-filters"
                        "DEU-0"
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
                  "addon@darkreader.org" = {
                    force = true;
                    settings = {
                      syncSettings = false;
                      schemeVersion = 2;
                      enabled = true;
                      enabledByDefault = true;
                      enabledFor = [ ];
                      disabledFor = [ "github.com" ];
                      changeBrowserTheme = false;
                      detectDarkTheme = true;
                      enableContextMenus = false;
                      enableForPDF = true;
                      enableForProtectedPages = false;
                      fetchNews = true;
                      syncSitesFixes = false;
                      automation = {
                        enabled = false;
                        mode = "";
                        behavior = "OnOff";
                      };
                      time = {
                        activation = "18:00";
                        deactivation = "9:00";
                      };
                      theme = {
                        mode = 1;
                        brightness = 100;
                        contrast = 100;
                        grayscale = 0;
                        sepia = 0;
                        useFont = false;
                        fontFamily = "Open Sans";
                        textStroke = 0;
                        engine = "dynamicTheme";
                        stylesheet = "";
                        darkSchemeBackgroundColor = "#181a1b";
                        darkSchemeTextColor = "#e8e6e3";
                        lightSchemeBackgroundColor = "#dcdad7";
                        lightSchemeTextColor = "#181a1b";
                        scrollbarColor = "";
                        selectionColor = "auto";
                        styleSystemControls = false;
                        lightColorScheme = "Default";
                        darkColorScheme = "Default";
                        immediateModify = false;
                      };
                    };
                  };
                  "redirector@einaregilsson.com" = {
                    force = true;
                    settings = {
                      disabled = false;
                      enableNotifications = false;
                      redirects =
                        map
                          (
                            r:
                            r
                            // {
                              error = null;
                              excludePattern = "";
                              patternDesc = "";
                              patternType = "R";
                              processMatches = "noProcessing";
                              disabled = false;
                              grouped = false;
                              appliesTo = [ "main_frame" ];
                            }
                          )
                          [
                            {
                              description = "Youtube";
                              includePattern = ''(.*\.)?youtube\.com/(.*)'';
                              redirectUrl = "https://${globals.services.invidious.domain}/$2";
                              exampleUrl = "https://www.youtube.com/watch?v=9szhjhO9epA";
                              exampleResult = "https://${globals.services.invidious.domain}/watch?v=9szhjhO9epA";
                            }
                            {
                              description = "Youtu.be";
                              includePattern = ''(.*\.)?youtu\.be/(.*)'';
                              redirectUrl = "https://${globals.services.invidious.domain}/$2";
                              exampleUrl = "https://www.youtu.be/watch?v=9szhjhO9epA";
                              exampleResult = "https://${globals.services.invidious.domain}/watch?v=9szhjhO9epA";
                            }
                            {
                              description = "Reddit";
                              includePattern = ''(.*\.)?reddit\.com/(.*)'';
                              redirectUrl = "https://old.reddit.com/$2";
                              exampleUrl = "https://www.reddit.com/r/NixOS";
                              exampleResult = "https://old.reddit.com/r/NixOS";
                            }
                            {
                              description = "Redd.it";
                              includePattern = ''(.*\.)?redd\.it/(.*)'';
                              redirectUrl = "https://old.reddit.com/$2";
                              exampleUrl = "https://redd.it/r/NixOS";
                              exampleResult = "https://old.reddit.com/r/NixOS";
                            }
                          ];
                    };
                  };
                };
            };

            settings = {
              "extensions.autoDisableScopes" = 0;
              "browser.bookmarks.showMobileBookmarks" = true;
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "browser.search.suggest.enabled" = false;
              "browser.search.suggest.enabled.private" = false;
              "browser.urlbar.suggest.searches" = false;
              "browser.urlbar.showSearchSuggestionsFirst" = false;
              "browser.topsites.contile.enabled" = false;
              "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
              "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
              "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
              "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
              "browser.newtabpage.activity-stream.showSponsored" = false;
              "browser.newtabpage.activity-stream.system.showSponsored" = false;
              "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
              "identity.sync.tokenserver.uri" =
                "https://${globals.services.firefox-syncserver.domain}/1.0/sync/1.5";
            }
            // lib.mapAttrs' (
              id: _: lib.nameValuePair "extensions.webextensions.ExtensionStorageIDB.migrated.${id}" false
            ) extensions.settings;

            search = {
              # default = "Kagi";
              default = "SearXNG";
              # privateDefault = "Kagi";
              privateDefault = "google";
              engines = {
                "SearXNG" = {
                  urls = [
                    {
                      template = "https://${globals.services.searx.domain}/search";
                      params = [
                        {
                          name = "q";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  icon = "https://search.swarsel.win/favicon.ico";
                  updateInterval = 24 * 60 * 60 * 1000; # every day
                  definedAliases = [ "@sx" ];
                };
                "Kagi" = {
                  urls = [
                    {
                      template = "https://kagi.com/search";
                      params = [
                        {
                          name = "q";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  icon = "https://kagi.com/favicon.ico";
                  updateInterval = 24 * 60 * 60 * 1000; # every day
                  definedAliases = [ "@k" ];
                };

                "Nix Packages" = {
                  urls = [
                    {
                      template = "https://search.nixos.org/packages";
                      params = [
                        {
                          name = "type";
                          value = "packages";
                        }
                        {
                          name = "query";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                  definedAliases = [ "@np" ];
                };

                "NixOS Wiki" = {
                  urls = [
                    {
                      template = "https://nixos.wiki/index.php?search={searchTerms}";
                    }
                  ];
                  icon = "https://nixos.wiki/favicon.png";
                  updateInterval = 24 * 60 * 60 * 1000; # every day
                  definedAliases = [ "@nw" ];
                };

                "NixOS Options" = {
                  urls = [
                    {
                      template = "https://search.nixos.org/options";
                      params = [
                        {
                          name = "query";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];

                  icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                  definedAliases = [ "@no" ];
                };

                "Home Manager Options" = {
                  urls = [
                    {
                      template = "https://home-manager-options.extranix.com/";
                      params = [
                        {
                          name = "query";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];

                  icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                  definedAliases = [
                    "@hm"
                    "@ho"
                    "@hmo"
                  ];
                };

                youtube = {
                  name = "YouTube";
                  urls = [
                    {
                      template = "https://www.youtube.com/results";
                      params = [
                        {
                          name = "search_query";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  icon = "https://www.youtube.com/favicon.ico";
                  updateInterval = 24 * 60 * 60 * 1000;
                  definedAliases = [ "@yt" ];
                };

                github = {
                  name = "GitHub";
                  urls = [
                    {
                      template = "https://github.com/search";
                      params = [
                        {
                          name = "q";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  icon = "https://github.com/favicon.ico";
                  updateInterval = 24 * 60 * 60 * 1000;
                  definedAliases = [ "@gh" ];
                };

                "Confluence search" = {
                  urls = [
                    {
                      template = "https://vbc.atlassian.net/wiki/search";
                      params = [
                        {
                          name = "text";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];

                  definedAliases = [
                    "@c"
                    "@cf"
                    "@confluence"
                  ];
                };

                "Jira search" = {
                  urls = [
                    {
                      template = "https://vbc.atlassian.net/issues/";
                      params = [
                        {
                          name = "jql";
                          value = "textfields ~ \"{searchTerms}*\"&wildcardFlag=true";
                        }
                      ];
                    }
                  ];

                  definedAliases = [
                    "@j"
                    "@jire"
                  ];
                };

                "google".metaData.alias = "@g";
              };
              force = true; # this is required because otherwise the search.json.mozlz4 symlink gets replaced on every firefox restart
            };
          };
        };
      };
    };
}
