{ pkgs, lib, ... }:
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
  home.packages = with pkgs; [
    stable.teams-for-linux
    shellcheck
    dig
    docker
    postman
    rclone
    awscli2
    libguestfs-with-appliance
  ];

  programs = {
    git.userEmail = "leon.schwarzaeugl@imba.oeaw.ac.at";

    zsh = {
      cdpath = [
        "~/Documents/Work"
      ];
      dirHashes = {
        d = "$HOME/.dotfiles";
        w = "$HOME/Documents/Work";
        s = "$HOME/.dotfiles/secrets";
        pr = "$HOME/Documents/Private";
        ac = "$HOME/.ansible/collections/ansible_collections/vbc/linux/roles";
      };
    };


    ssh = {
      matchBlocks = {
        "uc" = {
          hostname = "uc.clip.vbc.ac.at";
          user = "stack";
        };
        "uc-stg" = {
          hostname = "uc.staging.clip.vbc.ac.at";
          user = "stack";
        };
        "cbe" = {
          hostname = "cbe.vbc.ac.at";
          user = "dc_adm_schwarzaeugl";
        };
        "cbe-stg" = {
          hostname = "cbe.staging.vbc.ac.at";
          user = "dc_adm_schwarzaeugl";
        };
        "*.vbc.ac.at" = {
          user = "dc_adm_schwarzaeugl";
        };
      };
    };

    firefox = {
      profiles = {
        dc_adm = {
          id = 1;

          isDefault = false;
          userChrome = builtins.readFile ../../../programs/firefox/chrome/userChrome.css;
          extensions = with pkgs.nur.repos.rycee.firefox-addons; [
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
        cl_adm = {
          id = 2;

          isDefault = false;
          userChrome = builtins.readFile ../../../programs/firefox/chrome/userChrome.css;
          extensions = with pkgs.nur.repos.rycee.firefox-addons; [
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
        ws_adm = {
          id = 3;

          isDefault = false;
          userChrome = builtins.readFile ../../../programs/firefox/chrome/userChrome.css;
          extensions = with pkgs.nur.repos.rycee.firefox-addons; [
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

    chromium = {
      enable = true;
      package = pkgs.chromium;

      extensions = [
        # 1password
        "gejiddohjgogedgjnonbofjigllpkmbf"
        # dark reader
        "eimadpbcbfnmbkopoojfekhnkhdbieeh"
        # ublock origin
        "cjpalhdlnbpafiamejdnhcphjbkeiagm"
        # i still dont care about cookies
        "edibdbjcniadpccecjdfdjjppcpchdlm"
        # browserpass
        "naepdomgkenhinolocfifgehidddafch"
      ];
    };
  };

  xdg = {
    mimeApps = {
      defaultApplications = {
        "x-scheme-handler/msteams" = [ "teams-for-linux.desktop" ];
      };
    };
    desktopEntries =
      let
        terminal = false;
        categories = [ "Application" ];
        icon = "firefox";
      in
      {
        firefox_dc = {
          name = "Firefox (dc_adm)";
          genericName = "Firefox dc";
          exec = "firefox -p dc_adm";
          inherit terminal categories icon;
        };

        firefox_ws = {
          name = "Firefox (ws_adm)";
          genericName = "Firefox ws";
          exec = "firefox -p ws_adm";
          inherit terminal categories icon;
        };

        firefox_cl = {
          name = "Firefox (cl_adm)";
          genericName = "Firefox cl";
          exec = "firefox -p cl_adm";
          inherit terminal categories icon;
        };

      };
  };

}
