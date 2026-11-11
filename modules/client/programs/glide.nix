{
  flake-file.inputs.glide-nix = {
    inputs = {
      home-manager.follows = "home-manager";
      nixpkgs.follows = "nixpkgs";
    };
    url = "github:glide-browser/glide.nix";
  };

  flake.modules.homeManager.glide =
    {
      root,
      config,
      lib,
      pkgs,
      globals,
      ...
    }:
    let
      nixIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      oneDayMs = 24 * 60 * 60 * 1000;
      profile = rec {
        extensions = {
          packages =
            with pkgs.nur.repos.rycee.firefox-addons;
            [
              tampermonkey
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
              widegithub
              enhanced-github
              don-t-fuck-with-paste
              redirector
              readeck
              yubal
            ]
            ++ lib.optional config.programs.password-store.enable browserpass;

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
              "addon@darkreader.org" = {
                force = true;
                settings = {
                  automation = {
                    behavior = "OnOff";
                    enabled = false;
                    mode = "";
                  };
                  changeBrowserTheme = false;
                  detectDarkTheme = true;
                  disabledFor = [ "github.com" ];
                  enableContextMenus = false;
                  enableForPDF = true;
                  enableForProtectedPages = false;
                  enabled = true;
                  enabledByDefault = true;
                  enabledFor = [ ];
                  fetchNews = true;
                  schemeVersion = 2;
                  syncSettings = false;
                  syncSitesFixes = false;
                  theme = {
                    brightness = 100;
                    contrast = 100;
                    darkColorScheme = "Default";
                    darkSchemeBackgroundColor = "#181a1b";
                    darkSchemeTextColor = "#e8e6e3";
                    engine = "dynamicTheme";
                    fontFamily = "Open Sans";
                    grayscale = 0;
                    immediateModify = false;
                    lightColorScheme = "Default";
                    lightSchemeBackgroundColor = "#dcdad7";
                    lightSchemeTextColor = "#181a1b";
                    mode = 1;
                    scrollbarColor = "";
                    selectionColor = "auto";
                    sepia = 0;
                    styleSystemControls = false;
                    stylesheet = "";
                    textStroke = 0;
                    useFont = false;
                  };
                  time = {
                    activation = "18:00";
                    deactivation = "9:00";
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
                          appliesTo = [ "main_frame" ];
                          disabled = false;
                          error = null;
                          excludePattern = "";
                          grouped = false;
                          patternDesc = "";
                          patternType = "R";
                          processMatches = "noProcessing";
                        }
                      )
                      [
                        {
                          description = "Youtube";
                          exampleResult = "https://${globals.services.invidious.domain}/watch?v=9szhjhO9epA";
                          exampleUrl = "https://www.youtube.com/watch?v=9szhjhO9epA";
                          includePattern = ''(.*\.)?youtube\.com/(.*)'';
                          redirectUrl = "https://${globals.services.invidious.domain}/$2";
                        }
                        {
                          description = "Youtu.be";
                          exampleResult = "https://${globals.services.invidious.domain}/watch?v=9szhjhO9epA";
                          exampleUrl = "https://www.youtu.be/watch?v=9szhjhO9epA";
                          includePattern = ''(.*\.)?youtu\.be/(.*)'';
                          redirectUrl = "https://${globals.services.invidious.domain}/$2";
                        }
                        {
                          description = "Reddit";
                          exampleResult = "https://old.reddit.com/r/NixOS";
                          exampleUrl = "https://www.reddit.com/r/NixOS";
                          includePattern = ''(.*\.)?reddit\.com/(.*)'';
                          redirectUrl = "https://old.reddit.com/$2";
                        }
                        {
                          description = "Redd.it";
                          exampleResult = "https://old.reddit.com/r/NixOS";
                          exampleUrl = "https://redd.it/r/NixOS";
                          includePattern = ''(.*\.)?redd\.it/(.*)'';
                          redirectUrl = "https://old.reddit.com/$2";
                        }
                      ];
                };
              };
              "uBlock0@raymondhill.net" = {
                force = true;
                settings = rec {
                  cloudStorageEnabled = false;
                  externalLists = lib.concatStringsSep "\n" importedLists;
                  importedLists = [
                    "https://filters.adtidy.org/extension/ublock/filters/3.txt"
                    "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
                  ];
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
                  uiAccentCustom = true;
                  uiAccentCustom0 = config.lib.stylix.colors.withHashtag.base0C;
                  uiTheme = "dark";
                };
              };
            };
        };
        search = {
          # default = "Kagi";
          default = "SearXNG";
          engines = {
            "Confluence search" = {
              definedAliases = [
                "@c"
                "@cf"
                "@confluence"
              ];
              urls = [
                {
                  params = [
                    {
                      name = "text";
                      value = "{searchTerms}";
                    }
                  ];
                  template = "https://vbc.atlassian.net/wiki/search";
                }
              ];
            };
            "Home Manager Options" = {
              definedAliases = [
                "@hm"
                "@ho"
                "@hmo"
              ];
              icon = nixIcon;
              urls = [
                {
                  params = [
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                  template = "https://home-manager-options.extranix.com/";
                }
              ];
            };
            "Jira search" = {
              definedAliases = [
                "@j"
                "@jire"
              ];
              urls = [
                {
                  params = [
                    {
                      name = "jql";
                      value = "textfields ~ \"{searchTerms}*\"&wildcardFlag=true";
                    }
                  ];
                  template = "https://vbc.atlassian.net/issues/";
                }
              ];
            };
            Kagi = {
              definedAliases = [ "@k" ];
              icon = "https://kagi.com/favicon.ico";
              updateInterval = oneDayMs;
              urls = [
                {
                  params = [
                    {
                      name = "q";
                      value = "{searchTerms}";
                    }
                  ];
                  template = "https://kagi.com/search";
                }
              ];
            };
            "Nix Packages" = {
              definedAliases = [ "@np" ];
              icon = nixIcon;
              urls = [
                {
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
                  template = "https://search.nixos.org/packages";
                }
              ];
            };
            "NixOS Options" = {
              definedAliases = [ "@no" ];
              icon = nixIcon;
              urls = [
                {
                  params = [
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                  template = "https://search.nixos.org/options";
                }
              ];
            };
            "NixOS Wiki" = {
              definedAliases = [ "@nw" ];
              icon = "https://nixos.wiki/favicon.png";
              updateInterval = oneDayMs;
              urls = [
                {
                  template = "https://nixos.wiki/index.php?search={searchTerms}";
                }
              ];
            };
            SearXNG = {
              definedAliases = [ "@sx" ];
              icon = "https://${globals.services.searx.domain}/favicon.ico";
              updateInterval = oneDayMs;
              urls = [
                {
                  params = [
                    {
                      name = "q";
                      value = "{searchTerms}";
                    }
                  ];
                  template = "https://${globals.services.searx.domain}/search";
                }
              ];
            };
            bing.metaData.hidden = true;
            ddg.metaData.hidden = true;
            ecosia.metaData.hidden = true;
            github = {
              definedAliases = [ "@gh" ];
              icon = "https://github.com/favicon.ico";
              name = "GitHub";
              updateInterval = oneDayMs;
              urls = [
                {
                  params = [
                    {
                      name = "q";
                      value = "{searchTerms}";
                    }
                  ];
                  template = "https://github.com/search";
                }
              ];
            };
            google = {
              definedAliases = [ "@g" ];
              icon = "https://www.google.com/favicon.ico";
              name = "Google";
              urls = [
                {
                  params = [
                    {
                      name = "q";
                      value = "{searchTerms}";
                    }
                  ];
                  template = "https://www.google.com/search";
                }
              ];
            };
            perplexity.metaData.hidden = true;
            wikipedia.metaData.hidden = true;
            youtube = {
              definedAliases = [ "@yt" ];
              icon = "https://www.youtube.com/favicon.ico";
              name = "YouTube";
              updateInterval = oneDayMs;
              urls = [
                {
                  params = [
                    {
                      name = "search_query";
                      value = "{searchTerms}";
                    }
                  ];
                  template = "https://www.youtube.com/results";
                }
              ];
            };
          };
          force = true; # this is required because otherwise the search.json.mozlz4 symlink gets replaced on every firefox restart
          # privateDefault = "Kagi";
          privateDefault = "google";
        };
        settings = {
          "browser.bookmarks.showMobileBookmarks" = true;
          "browser.download.open_pdf_attachments_inline" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.system.showSponsored" = false;
          "browser.profiles.enabled" = false;
          "browser.search.suggest.enabled" = false;
          "browser.search.suggest.enabled.private" = false;
          "browser.toolbars.bookmarks.visibility" = "never";
          "browser.topsites.contile.enabled" = false;
          "browser.uiCustomization.state" = builtins.toJSON {
            currentVersion = 24;
            dirtyAreaCache = [
              "unified-extensions-area"
              "nav-bar"
              "vertical-tabs"
              "toolbar-menubar"
              "TabsToolbar"
              "PersonalToolbar"
            ];
            newElementCount = 14;
            placements = {
              PersonalToolbar = [ ];
              TabsToolbar = [
                "firefox-view-button"
                "tabbrowser-tabs"
                "new-tab-button"
                "alltabs-button"
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
              vertical-tabs = [ ];
              widget-overflow-fixed-list = [ ];
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
          };
          "browser.urlbar.showSearchSuggestionsFirst" = false;
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.urlbar.suggest.searches" = false;
          "extensions.autoDisableScopes" = 0;
          "identity.sync.tokenserver.uri" =
            "https://${globals.services.firefox-syncserver.domain}/1.0/sync/1.5";
        }
        // lib.mapAttrs' (
          id: _: lib.nameValuePair "extensions.webextensions.ExtensionStorageIDB.migrated.${id}" false
        ) extensions.settings;
      };
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "glide" ];
        programs = {
          glide-browser = {
            config = lib.mkBefore ''
              /// <reference types="./glide.d.ts" />

              glide.o.hint_size = "16px";

              glide.o.hint_label_generator = glide.hints.label_generators.numeric;
              glide.o.keymaps_use_physical_layout = "force";
              glide.o.yank_highlight = "${config.lib.stylix.colors.withHashtag.base09}";
            '';
            enable = true;
            nativeMessagingHosts = lib.optionals config.programs.password-store.enable [ pkgs.browserpass ];
            policies = {
              AppAutoUpdate = false;
              BackgroundAppUpdate = false;
              Certificates = {
                ImportEnterpriseRoots = true;
                Install = [ (root "files/public/certs/ca.crt") ];
              };
              DisableBuiltinPDFViewer = true;
              DisableFirefoxAccounts = false;
              DisableFirefoxScreenshots = true;
              DisableFirefoxStudies = true;
              DisableMasterPasswordCreation = true;
              DisableProfileImport = true;
              DisableProfileRefresh = true;
              DisableTelemetry = true;
              DontCheckDefaultBrowser = true;
              EnableTrackingProtection = {
                Cryptomining = true;
                EmailTracking = true;
                Fingerprinting = true;
                Locked = true;
                Value = true;
              };
              ExtensionUpdate = false;
              FirefoxHome = {
                Highlights = true;
                Locked = true;
                Search = true;
                SponsoredTopSites = false;
                TopSites = true;
              };
              FirefoxSuggest = {
                ImproveSuggest = false;
                Locked = true;
                SponsoredSuggestions = false;
                WebSuggestions = false;
              };
              Handlers = {
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
                mimeTypes."application/pdf".action = "saveToDisk";
              };
              NoDefaultBookmarks = true;
              OfferToSaveLogins = false;
              PDFjs = {
                EnablePermissions = false;
                Enabled = false;
              };
              PasswordManagerEnabled = false;
              SanitizeOnShutdown = {
                Cache = true;
                Cookies = false;
                Downloads = true;
                FormData = true;
                History = false;
                Locked = true;
                OfflineApps = true;
                Sessions = false;
                SiteSettings = false;
              };
              SearchEngines.PreventInstalls = true;
              UserMessaging = {
                ExtensionRecommendations = false;
                FeatureRecommendations = false;
                Locked = true;
                MoreFromMozilla = false;
                SkipOnboarding = true;
                UrlbarInterventions = false;
                WhatsNew = false;
              };
            };
            profiles.default = lib.recursiveUpdate profile {
              id = 0;
              isDefault = true;
              settings = {
                "browser.sessionstore.max_resumed_crashes" = 0;
                "browser.sessionstore.resume_from_crash" = false;
                "browser.startup.homepage" = "https://lobste.rs";
                "browser.startup.page" = 1;
              };
            };
          };
          zsh.sessionVariables.MOZ_DISABLE_RDD_SANDBOX = "1";
        };
        _module.args.glideProfile = profile;
        home.activation.extensionSyncStorage =
          let
            invidiousInstances = [
              "yewtu.be"
              globals.services.invidious.domain
            ];
            sponsorblockGrant = ''."sponsorBlocker@ajay.app" |= {permissions: [], data_collection: []} + . + {origins: ((.origins // []) + ${
              builtins.toJSON (
                lib.concatMap (i: [
                  "https://*.${i}/*"
                  "http://*.${i}/*"
                ]) invidiousInstances
              )
            } | unique)}'';
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            profileDir="$HOME/.config/glide/glide/default"
            prefs="$profileDir/extension-preferences.json"
            if [ ! -f "$profileDir/storage-sync-v2.sqlite" ]; then
              verboseEcho "extension sync storage does not exist yet, skipping"
            elif ${pkgs.procps}/bin/pgrep -x .glide-wrapped > /dev/null; then
              warnEcho "glide is running, skipping the extension sync storage update"
            else
              ${lib.concatMapAttrsStringSep "\n"
                (id: file: ''
                  run ${pkgs.sqlite}/bin/sqlite3 "$profileDir/storage-sync-v2.sqlite" \
                    "INSERT INTO storage_sync_data(ext_id, data) VALUES('${id}', json(readfile('${file}'))) ON CONFLICT(ext_id) DO UPDATE SET data = json_patch(data, json(readfile('${file}'))), sync_change_counter = sync_change_counter + 1;" \
                    || warnEcho "failed to update the sync storage of ${id}"
                '')
                (
                  lib.mapAttrs (id: data: pkgs.writeText "${id}-sync-storage.json" (builtins.toJSON data)) {
                    "sponsorBlocker@ajay.app" = {
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
                      supportInvidious = true;
                    };
                    "yubal@guillevc.xyz".yubalUrl = "https://${globals.services.yubal.domain}";
                  }
                )
              }
              if [ -f "$prefs" ]; then
                run sh -c '${lib.getExe pkgs.jq} --indent 1 "$1" "$2" > "$2.tmp" && mv "$2.tmp" "$2"' _ ${lib.escapeShellArg sponsorblockGrant} "$prefs" \
                  || warnEcho "failed to grant sponsorblock its invidious origins"
              fi
            fi
          '';
      };
    };
}
