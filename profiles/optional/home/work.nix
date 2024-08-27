{ pkgs, ... }:

{
  home.packages = with pkgs; [
    teams-for-linux
    google-chrome
    shellcheck
    dig
  ];

  programs.ssh = {
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

  programs.firefox = {
    profiles = {
      dc_adm = {
        id = 1;
        # 
        # isDefault = false;
        # userChrome = builtins.readFile ../../../programs/firefox/chrome/userChrome.css;
        # extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        #   tridactyl
        #   browserpass
        #   clearurls
        #   darkreader
        #   enhancer-for-youtube
        #   istilldontcareaboutcookies
        #   translate-web-pages
        #   ublock-origin
        #   reddit-enhancement-suite
        #   sponsorblock
        #   web-archives
        #   onepassword-password-manager
        #   single-file
        #   widegithub
        #   enhanced-github
        #   unpaywall
        #   don-t-fuck-with-paste
        #   plasma-integration
        # ];
        # 
        # search.engines = {
        #   "Nix Packages" = {
        #     urls = [{
        #       template = "https://search.nixos.org/packages";
        #       params = [
        #         { name = "type"; value = "packages"; }
        #         { name = "query"; value = "{searchTerms}"; }
        #       ];
        #     }];
        #     icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        #     definedAliases = [ "@np" ];
        #   };
        # 
        #   "NixOS Wiki" = {
        #     urls = [{
        #       template = "https://nixos.wiki/index.php?search={searchTerms}";
        #     }];
        #     iconUpdateURL = "https://nixos.wiki/favicon.png";
        #     updateInterval = 24 * 60 * 60 * 1000; # every day
        #     definedAliases = [ "@nw" ];
        #   };
        # 
        #   "NixOS Options" = {
        #     urls = [{
        #       template = "https://search.nixos.org/options";
        #       params = [
        #         { name = "query"; value = "{searchTerms}"; }
        #       ];
        #     }];
        # 
        #     icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        #     definedAliases = [ "@no" ];
        #   };
        # 
        #   "Home Manager Options" = {
        #     urls = [{
        #       template = "https://home-manager-options.extranix.com/";
        #       params = [
        #         { name = "query"; value = "{searchTerms}"; }
        #       ];
        #     }];
        # 
        #     icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        #     definedAliases = [ "@hm" "@ho" "@hmo" ];
        #   };
        # 
        #   "Google".metaData.alias = "@g";
        # };
        # search.force = true; # this is required because otherwise the search.json.mozlz4 symlink gets replaced on every firefox restart
        # 
      };
      cl_adm = {
        id = 2;
        # 
        # isDefault = false;
        # userChrome = builtins.readFile ../../../programs/firefox/chrome/userChrome.css;
        # extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        #   tridactyl
        #   browserpass
        #   clearurls
        #   darkreader
        #   enhancer-for-youtube
        #   istilldontcareaboutcookies
        #   translate-web-pages
        #   ublock-origin
        #   reddit-enhancement-suite
        #   sponsorblock
        #   web-archives
        #   onepassword-password-manager
        #   single-file
        #   widegithub
        #   enhanced-github
        #   unpaywall
        #   don-t-fuck-with-paste
        #   plasma-integration
        # ];
        # 
        # search.engines = {
        #   "Nix Packages" = {
        #     urls = [{
        #       template = "https://search.nixos.org/packages";
        #       params = [
        #         { name = "type"; value = "packages"; }
        #         { name = "query"; value = "{searchTerms}"; }
        #       ];
        #     }];
        #     icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        #     definedAliases = [ "@np" ];
        #   };
        # 
        #   "NixOS Wiki" = {
        #     urls = [{
        #       template = "https://nixos.wiki/index.php?search={searchTerms}";
        #     }];
        #     iconUpdateURL = "https://nixos.wiki/favicon.png";
        #     updateInterval = 24 * 60 * 60 * 1000; # every day
        #     definedAliases = [ "@nw" ];
        #   };
        # 
        #   "NixOS Options" = {
        #     urls = [{
        #       template = "https://search.nixos.org/options";
        #       params = [
        #         { name = "query"; value = "{searchTerms}"; }
        #       ];
        #     }];
        # 
        #     icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        #     definedAliases = [ "@no" ];
        #   };
        # 
        #   "Home Manager Options" = {
        #     urls = [{
        #       template = "https://home-manager-options.extranix.com/";
        #       params = [
        #         { name = "query"; value = "{searchTerms}"; }
        #       ];
        #     }];
        # 
        #     icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        #     definedAliases = [ "@hm" "@ho" "@hmo" ];
        #   };
        # 
        #   "Google".metaData.alias = "@g";
        # };
        # search.force = true; # this is required because otherwise the search.json.mozlz4 symlink gets replaced on every firefox restart
        # 
      };
      ws_adm = {
        id = 3;
        # 
        # isDefault = false;
        # userChrome = builtins.readFile ../../../programs/firefox/chrome/userChrome.css;
        # extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        #   tridactyl
        #   browserpass
        #   clearurls
        #   darkreader
        #   enhancer-for-youtube
        #   istilldontcareaboutcookies
        #   translate-web-pages
        #   ublock-origin
        #   reddit-enhancement-suite
        #   sponsorblock
        #   web-archives
        #   onepassword-password-manager
        #   single-file
        #   widegithub
        #   enhanced-github
        #   unpaywall
        #   don-t-fuck-with-paste
        #   plasma-integration
        # ];
        # 
        # search.engines = {
        #   "Nix Packages" = {
        #     urls = [{
        #       template = "https://search.nixos.org/packages";
        #       params = [
        #         { name = "type"; value = "packages"; }
        #         { name = "query"; value = "{searchTerms}"; }
        #       ];
        #     }];
        #     icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        #     definedAliases = [ "@np" ];
        #   };
        # 
        #   "NixOS Wiki" = {
        #     urls = [{
        #       template = "https://nixos.wiki/index.php?search={searchTerms}";
        #     }];
        #     iconUpdateURL = "https://nixos.wiki/favicon.png";
        #     updateInterval = 24 * 60 * 60 * 1000; # every day
        #     definedAliases = [ "@nw" ];
        #   };
        # 
        #   "NixOS Options" = {
        #     urls = [{
        #       template = "https://search.nixos.org/options";
        #       params = [
        #         { name = "query"; value = "{searchTerms}"; }
        #       ];
        #     }];
        # 
        #     icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        #     definedAliases = [ "@no" ];
        #   };
        # 
        #   "Home Manager Options" = {
        #     urls = [{
        #       template = "https://home-manager-options.extranix.com/";
        #       params = [
        #         { name = "query"; value = "{searchTerms}"; }
        #       ];
        #     }];
        # 
        #     icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        #     definedAliases = [ "@hm" "@ho" "@hmo" ];
        #   };
        # 
        #   "Google".metaData.alias = "@g";
        # };
        # search.force = true; # this is required because otherwise the search.json.mozlz4 symlink gets replaced on every firefox restart
        # 
      };
    };
  };

  xdg.desktopEntries =
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

  programs.git.userEmail = "leon.schwarzaeugl@imba.oeaw.ac.at";

}
