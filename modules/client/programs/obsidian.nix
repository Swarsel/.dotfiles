{
  flake.modules.homeManager.obsidian =
    {
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    let
      inherit (confLib.getConfig.repo.secrets.common.obsidian) userIgnoreFilters;
      name = "Main";
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "obsidian" ];
        programs.obsidian =
          let
            pluginSource = pkgs.nur.repos.swarsel;
          in
          {
            enable = true;
            package = pkgs.obsidian;
            defaultSettings = {
              app = {
                inherit userIgnoreFilters;
                alwaysUpdateLinks = true;
                attachmentFolderPath = "attachments";
                newFileLocation = "current";
                spellcheck = false;
                vimMode = false;
              };
              # communityPlugins = with pkgs.swarsel-nix; [
              communityPlugins = with pluginSource; [
                advanced-tables
                calendar
                file-hider
                linter
                omnisearch
                sort-and-permute-lines
                tag-wrangler
                tray
              ];
              corePlugins = [
                "backlink"
                "bookmarks"
                "canvas"
                "command-palette"
                "daily-notes"
                "editor-status"
                "file-explorer"
                "file-recovery"
                "global-search"
                "graph"
                "note-composer"
                "outgoing-link"
                "outline"
                "page-preview"
                "properties"
                "slides"
                "switcher"
                "tag-pane"
                "templates"
                "word-count"
              ];
              hotkeys = {
                "editor:delete-paragraph" = [ ];
                "editor:save-file" = [ ];
                "graph:open" = [ ];
                "omnisearch:show-modal" = [
                  {
                    key = "S";
                    modifiers = [
                      "Mod"
                    ];
                  }
                ];
              };
            };
            vaults = {
              ${name} = {
                settings = {
                  appearance.baseFontSize = lib.mkForce 19;
                  # communityPlugins = with pkgs.swarsel-nix; [
                  communityPlugins = with pluginSource; [
                    {
                      enable = true;
                      pkg = advanced-tables;
                    }
                    {
                      enable = true;
                      pkg = calendar;
                    }
                    {
                      enable = true;
                      pkg = sort-and-permute-lines;
                    }
                    {
                      enable = true;
                      pkg = tag-wrangler;
                    }
                    {
                      enable = true;
                      pkg = tray;
                      settings = {
                        createTrayIcon = true;
                        hideOnLaunch = true;
                        hideTaskbarIcon = false;
                        launchOnStartup = false;
                        runInBackground = true;
                      };
                    }
                    {
                      enable = true;
                      pkg = file-hider;
                      settings = {
                        hidden = true;
                        hiddenList = [
                          "attachments"
                          "images"
                          "ltximg"
                          "logseq"
                        ];
                      };
                    }
                    {
                      enable = true;
                      pkg = linter;
                      settings = {
                        auto-correct-common-misspellings.skip-words-with-multiple-capitals = true;
                        convert-bullet-list-markers.enabled = true;
                      };
                    }
                    {
                      enable = true;
                      pkg = omnisearch;
                      settings.hideExcluded = true;
                    }
                  ];
                };
                target = "./Obsidian/${name}";
              };
            };
          };
        home.file = {
          "${config.programs.obsidian.vaults.${name}.target}/.obsidian/app.json".force = true;
          "${config.programs.obsidian.vaults.${name}.target}/.obsidian/appearance.json".force = true;
          "${config.programs.obsidian.vaults.${name}.target}/.obsidian/core-plugins.json".force = true;
        };
      };
    };
}
