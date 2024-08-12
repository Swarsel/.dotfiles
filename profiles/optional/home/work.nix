{ pkgs, ... }:

{
  home.packages = with pkgs; [
    teams-for-linux
    google-chrome
    thunderbird
    ansible
    dig
  ];

  programs.ssh = {
    matchBlocks = {
      "*.vbc.ac.at" = {
        user = "dc_adm_schwarzaeugl";
      };
    };
  };

  programs.firefox = {
    profiles = {
      dc_adm = {
        id = 1;

        isDefault = false;
        userChrome = builtins.readFile ../../../programs/firefox/chrome/userChrome.css;
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          tridactyl
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
        ];

        search.engines = {
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
        search.force = true; # this is required because otherwise the search.json.mozlz4 symlink gets replaced on every firefox restart

      };
      cl_adm = {
        id = 2;

        isDefault = false;
        userChrome = builtins.readFile ../../../programs/firefox/chrome/userChrome.css;
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          tridactyl
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
        ];

        search.engines = {
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
        search.force = true; # this is required because otherwise the search.json.mozlz4 symlink gets replaced on every firefox restart

      };
      ws_adm = {
        id = 3;

        isDefault = false;
        userChrome = builtins.readFile ../../../programs/firefox/chrome/userChrome.css;
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          tridactyl
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
        ];

        search.engines = {
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
        search.force = true; # this is required because otherwise the search.json.mozlz4 symlink gets replaced on every firefox restart

      };
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
    config = {
      common = {
        default = "wlr";
      };
    };
  };

  programs.git.userEmail = "leon.schwarzaeugl@imba.oeaw.ac.at";

}
