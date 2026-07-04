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

          sponsorblockActivation =
            let
              invidiousInstances = [
                "yewtu.be"
                globals.services.invidious.domain
              ];
              sbOrigins = pkgs.writeText "sponsorblock-origins.json" (
                builtins.toJSON (
                  lib.concatMap (i: [
                    "https://*.${i}/*"
                    "http://*.${i}/*"
                  ]) invidiousInstances
                )
              );
              sbGrant = pkgs.writeText "sponsorblock-grant.py" ''
                import json
                import sys

                prefs_file, origins_file = sys.argv[1:3]
                prefs = json.load(open(prefs_file))
                origins = json.load(open(origins_file))
                entry = prefs.setdefault("sponsorBlocker@ajay.app", {})
                entry.setdefault("permissions", [])
                entry.setdefault("data_collection", [])
                entry["origins"] = sorted(set(entry.get("origins", [])) | set(origins))
                json.dump(prefs, open(prefs_file, "w"), indent=1)
              '';
              sbJson = pkgs.writeText "sponsorblock-settings.json" (
                builtins.toJSON {
                  supportInvidious = true;
                  inherit invidiousInstances;
                  categorySelections = [
                    {
                      name = "sponsor";
                      option = 2;
                    }
                    {
                      name = "poi_highlight";
                      option = 1;
                    }
                    {
                      name = "exclusive_access";
                      option = 0;
                    }
                    {
                      name = "selfpromo";
                      option = 2;
                    }
                    {
                      name = "chapter";
                      option = 0;
                    }
                  ];
                }
              );
            in
            lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              sponsorblockPatch() {
                profileDir="$1"
                sbProc="$2"
                sbDb="$profileDir/storage-sync-v2.sqlite"
                sbPrefs="$profileDir/extension-preferences.json"
                if [ ! -f "$sbDb" ]; then
                  verboseEcho "sponsorblock: $sbDb does not exist yet, skipping"
                elif ${pkgs.procps}/bin/pgrep -x "$sbProc" > /dev/null; then
                  warnEcho "sponsorblock: $sbProc is running, skipping sync-storage update"
                else
                  run ${pkgs.sqlite}/bin/sqlite3 "$sbDb" \
                    "INSERT INTO storage_sync_data(ext_id, data) VALUES('sponsorBlocker@ajay.app', json(readfile('${sbJson}'))) ON CONFLICT(ext_id) DO UPDATE SET data = json_patch(data, json(readfile('${sbJson}'))), sync_change_counter = sync_change_counter + 1;" \
                    || warnEcho "sponsorblock: failed to update $sbDb"
                  if [ -f "$sbPrefs" ]; then
                    run ${pkgs.python3}/bin/python3 ${sbGrant} "$sbPrefs" ${sbOrigins} \
                      || warnEcho "sponsorblock: failed to update $sbPrefs"
                  fi
                fi
              }
              sponsorblockPatch "$HOME/.config/glide/glide/default" glide
              sponsorblockPatch "$HOME/.mozilla/firefox/default" firefox
            '';

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
              "browser.urlbar.suggest.quicksuggest.sponsored" = false;
              "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
              "browser.download.open_pdf_attachments_inline" = false;
              "browser.toolbars.bookmarks.visibility" = "never";
              "browser.uiCustomization.state" = builtins.toJSON {
                placements = {
                  widget-overflow-fixed-list = [ ];
                  unified-extensions-area = [
                    "sponsorblocker_ajay_app-browser-action"
                    "dontfuckwithpaste_raim_ist-browser-action"
                    "_72742915-c83b-4485-9023-b55dc5a1e730_-browser-action"
                    "_72bd91c9-3dc5-40a8-9b10-dec633c0873f_-browser-action"
                    "_f209234a-76f0-4735-9920-eb62507a54cd_-browser-action"
                    "idcac-pub_guus_ninja-browser-action"
                    "firefox_tampermonkey_net-browser-action"
                    "_74145f27-f039-47ce-a470-a662b129930a_-browser-action"
                    "_036a55b4-5e72-4d05-a06c-cba2dfcc134a_-browser-action"
                    "_d07ccf11-c0cd-4938-a265-2a4d6ad01189_-browser-action"
                    "_531906d3-e22f-4a6c-a102-8057b88a1a63_-browser-action"
                    "kde-connect_0xc0dedbad_com-browser-action"
                  ];
                  nav-bar = [
                    "personal-bookmarks"
                    "back-button"
                    "forward-button"
                    "stop-reload-button"
                    "urlbar-container"
                    "downloads-button"
                    "privatebrowsing-button"
                    "developer-button"
                    "vertical-spacer"
                    "reset-pbm-toolbar-button"
                    "_73a6fe31-595d-460b-a920-fcc0f8843232_-browser-action"
                    "_3c078156-979c-498b-8990-85f7987dd929_-browser-action"
                    "customizableui-special-spring14"
                    "ublock0_raymondhill_net-browser-action"
                    "addon_darkreader_org-browser-action"
                    "browserpass_maximbaz_com-browser-action"
                    "_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action"
                    "redirector_einaregilsson_com-browser-action"
                    "unified-extensions-button"
                  ];
                  toolbar-menubar = [ "menubar-items" ];
                  TabsToolbar = [
                    "firefox-view-button"
                    "tabbrowser-tabs"
                    "new-tab-button"
                    "alltabs-button"
                  ];
                  vertical-tabs = [ ];
                  PersonalToolbar = [ ];
                };
                seen = [
                  "reset-pbm-toolbar-button"
                  "dontfuckwithpaste_raim_ist-browser-action"
                  "redirector_einaregilsson_com-browser-action"
                  "_72742915-c83b-4485-9023-b55dc5a1e730_-browser-action"
                  "_72bd91c9-3dc5-40a8-9b10-dec633c0873f_-browser-action"
                  "_f209234a-76f0-4735-9920-eb62507a54cd_-browser-action"
                  "browserpass_maximbaz_com-browser-action"
                  "addon_darkreader_org-browser-action"
                  "idcac-pub_guus_ninja-browser-action"
                  "firefox_tampermonkey_net-browser-action"
                  "_74145f27-f039-47ce-a470-a662b129930a_-browser-action"
                  "_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action"
                  "_73a6fe31-595d-460b-a920-fcc0f8843232_-browser-action"
                  "_036a55b4-5e72-4d05-a06c-cba2dfcc134a_-browser-action"
                  "sponsorblocker_ajay_app-browser-action"
                  "_d07ccf11-c0cd-4938-a265-2a4d6ad01189_-browser-action"
                  "ublock0_raymondhill_net-browser-action"
                  "_3c078156-979c-498b-8990-85f7987dd929_-browser-action"
                  "_531906d3-e22f-4a6c-a102-8057b88a1a63_-browser-action"
                  "developer-button"
                  "kde-connect_0xc0dedbad_com-browser-action"
                ];
                dirtyAreaCache = [
                  "unified-extensions-area"
                  "nav-bar"
                  "vertical-tabs"
                  "toolbar-menubar"
                  "TabsToolbar"
                  "PersonalToolbar"
                ];
                currentVersion = 24;
                newElementCount = 14;
              };
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
