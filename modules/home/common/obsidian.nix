{ lib, config, pkgs, nixosConfig ? config, ... }:
let
  moduleName = "obsidian";
  inherit (nixosConfig.repo.secrets.common.obsidian) userIgnoreFilters;
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "enable ${moduleName} with settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    programs.obsidian =
      let
        name = "Main";
      in
      {
        enable = true;
        package = pkgs.obsidian;
        defaultSettings = {
          app = {
            attachmentFolderPath = "attachments";
            alwaysUpdateLinks = true;
            spellcheck = false;
            inherit userIgnoreFilters;
            vimMode = false;
            newFileLocation = "current";
          };
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
          communityPlugins = with pkgs.swarsel-nix; [
            advanced-tables
            calendar
            file-hider
            linter
            omnisearch
            sort-and-permute-lines
            tag-wrangler
            tray
          ];
        };
        vaults = {
          ${name} = {
            target = "./Obsidian/${name}";
            settings = {
              appearance = {
                baseFontSize = lib.mkForce 19;
              };
              communityPlugins = with pkgs.swarsel-nix; [
                {
                  pkg = advanced-tables;
                  enable = true;
                }
                {
                  pkg = calendar;
                  enable = true;
                }
                {
                  pkg = sort-and-permute-lines;
                  enable = true;
                }
                {
                  pkg = tag-wrangler;
                  enable = true;
                }
                {
                  pkg = tray;
                  enable = true;
                  settings = {
                    launchOnStartup = false;
                    hideOnLaunch = true;
                    runInBackground = true;
                    hideTaskbarIcon = false;
                    createTrayIcon = true;
                  };
                }
                {
                  pkg = file-hider;
                  enable = true;
                  settings =
                    {
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
                  pkg = linter;
                  enable = true;
                  settings = {
                    auto-correct-common-misspellings = {
                      skip-words-with-multiple-capitals = true;
                    };
                    convert-bullet-list-markers = {
                      enabled = true;
                    };
                  };
                }
                {
                  pkg = omnisearch;
                  enable = true;
                  settings = {
                    hideExcluded = true;
                  };
                }
              ];
            };
          };
        };
      };
  };
}
