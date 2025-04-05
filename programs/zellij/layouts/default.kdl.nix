{ config, pkgs }:
let
  inherit (config.lib.stylix) colors;
in
''
  layout {
         swap_tiled_layout name="vertical" {
             tab max_panes=5 {
                 pane split_direction="vertical" {
                     pane
                     pane { children; }
                 }
             }
             tab max_panes=8 {
                 pane split_direction="vertical" {
                     pane { children; }
                     pane { pane; pane; pane; pane; }
                 }
             }
             tab max_panes=12 {
                 pane split_direction="vertical" {
                     pane { children; }
                     pane { pane; pane; pane; pane; }
                     pane { pane; pane; pane; pane; }
                 }
             }
         }

         swap_tiled_layout name="horizontal" {
             tab max_panes=5 {
                 pane
                 pane
             }
             tab max_panes=8 {
                 pane {
                     pane split_direction="vertical" { children; }
                     pane split_direction="vertical" { pane; pane; pane; pane; }
                 }
             }
             tab max_panes=12 {
                 pane {
                     pane split_direction="vertical" { children; }
                     pane split_direction="vertical" { pane; pane; pane; pane; }
                     pane split_direction="vertical" { pane; pane; pane; pane; }
                 }
             }
         }

         swap_tiled_layout name="stacked" {
             tab min_panes=5 {
                 pane split_direction="vertical" {
                     pane
                     pane stacked=true { children; }
                 }
             }
         }

         swap_floating_layout name="staggered" {
             floating_panes
         }

         swap_floating_layout name="enlarged" {
             floating_panes max_panes=10 {
                 pane { x "5%"; y 1; width "90%"; height "90%"; }
                 pane { x "5%"; y 2; width "90%"; height "90%"; }
                 pane { x "5%"; y 3; width "90%"; height "90%"; }
                 pane { x "5%"; y 4; width "90%"; height "90%"; }
                 pane { x "5%"; y 5; width "90%"; height "90%"; }
                 pane { x "5%"; y 6; width "90%"; height "90%"; }
                 pane { x "5%"; y 7; width "90%"; height "90%"; }
                 pane { x "5%"; y 8; width "90%"; height "90%"; }
                 pane { x "5%"; y 9; width "90%"; height "90%"; }
                 pane focus=true { x 10; y 10; width "90%"; height "90%"; }
             }
         }

         swap_floating_layout name="spread" {
             floating_panes max_panes=1 {
                 pane {y "50%"; x "50%"; }
             }
             floating_panes max_panes=2 {
                 pane { x "1%"; y "25%"; width "45%"; }
                 pane { x "50%"; y "25%"; width "45%"; }
             }
             floating_panes max_panes=3 {
                 pane focus=true { y "55%"; width "45%"; height "45%"; }
                 pane { x "1%"; y "1%"; width "45%"; }
                 pane { x "50%"; y "1%"; width "45%"; }
             }
             floating_panes max_panes=4 {
                 pane { x "1%"; y "55%"; width "45%"; height "45%"; }
                 pane focus=true { x "50%"; y "55%"; width "45%"; height "45%"; }
                 pane { x "1%"; y "1%"; width "45%"; height "45%"; }
                 pane { x "50%"; y "1%"; width "45%"; height "45%"; }
             }
         }

         default_tab_template {
             children
             pane size=1 borderless=true {
                 plugin location="file://${pkgs.zjstatus}/bin/zjstatus.wasm" {
                     format_left   "{mode}#[bg=#${colors.base00}] {tabs}"
                     format_center ""
                     format_right  "#[bg=#${colors.base00},fg=#${colors.base02}]#[bg=#${colors.base02},fg=#${colors.base01},bold] #[bg=#${colors.base02},fg=#${colors.base01},bold] {session} #[bg=#${colors.base02},fg=#${colors.base01},bold]"
                     format_space  ""
                     format_hide_on_overlength "false"
                     format_precedence "lcr"

                     border_enabled  "false"
                     border_char     "─"
                     border_format   "#[fg=#6C7086]{char}"
                     border_position "top"

                     mode_normal        "#[bg=#${colors.base0B},fg=#${colors.base01},bold] NORMAL#[bg=#${colors.base01},fg=#${colors.base0B}]█"
                     mode_locked        "#[bg=#${colors.base04},fg=#${colors.base01},bold] LOCKED #[bg=#${colors.base01},fg=#${colors.base04}]█"
                     mode_resize        "#[bg=#${colors.base08},fg=#${colors.base01},bold] RESIZE#[bg=#${colors.base01},fg=#${colors.base08}]█"
                     mode_pane          "#[bg=#${colors.base0D},fg=#${colors.base01},bold] PANE#[bg=#${colors.base01},fg=#${colors.base0D}]█"
                     mode_tab           "#[bg=#${colors.base07},fg=#${colors.base01},bold] TAB#[bg=#${colors.base01},fg=#${colors.base07}]█"
                     mode_scroll        "#[bg=#${colors.base0A},fg=#${colors.base01},bold] SCROLL#[bg=#${colors.base01},fg=#${colors.base0A}]█"
                     mode_enter_search  "#[bg=#${colors.base0D},fg=#${colors.base01},bold] ENT-SEARCH#[bg=#${colors.base01},fg=#${colors.base0D}]█"
                     mode_search        "#[bg=#${colors.base0D},fg=#${colors.base01},bold] SEARCHARCH#[bg=#${colors.base01},fg=#${colors.base0D}]█"
                     mode_rename_tab    "#[bg=#${colors.base07},fg=#${colors.base01},bold] RENAME-TAB#[bg=#${colors.base01},fg=#${colors.base07}]█"
                     mode_rename_pane   "#[bg=#${colors.base0D},fg=#${colors.base01},bold] RENAME-PANE#[bg=#${colors.base01},fg=#${colors.base0D}]█"
                     mode_session       "#[bg=#${colors.base0E},fg=#${colors.base01},bold] SESSION#[bg=#${colors.base01},fg=#${colors.base0E}]█"
                     mode_move          "#[bg=#${colors.base0F},fg=#${colors.base01},bold] MOVE#[bg=#${colors.base01},fg=#${colors.base0F}]█"
                     mode_prompt        "#[bg=#${colors.base0D},fg=#${colors.base01},bold] PROMPT#[bg=#${colors.base01},fg=#${colors.base0D}]█"
                     mode_tmux          "#[bg=#${colors.base09},fg=#${colors.base01},bold] TMUX#[bg=#${colors.base01},fg=#${colors.base09}]█"

                     // formatting for inactive tabs
                     tab_normal              "#[bg=#${colors.base01},fg=#${colors.base0C}]█#[bg=#${colors.base0C},fg=#${colors.base01},bold]{index} #[bg=#${colors.base01},fg=#${colors.base0C},bold] {name}{floating_indicator}#[bg=#${colors.base01},fg=#${colors.base01},bold]█"
                     tab_normal_fullscreen   "#[bg=#${colors.base01},fg=#${colors.base0C}]█#[bg=#${colors.base0C},fg=#${colors.base01},bold]{index} #[bg=#${colors.base01},fg=#${colors.base0C},bold] {name}{fullscreen_indicator}#[bg=#${colors.base01},fg=#${colors.base01},bold]█"
                     tab_normal_sync         "#[bg=#${colors.base01},fg=#${colors.base0C}]█#[bg=#${colors.base0C},fg=#${colors.base01},bold]{index} #[bg=#${colors.base01},fg=#${colors.base0C},bold] {name}{sync_indicator}#[bg=#${colors.base01},fg=#${colors.base01},bold]█"

                     // formatting for the current active tab
                     tab_active              "#[bg=#${colors.base01},fg=#${colors.base09}]█#[bg=#${colors.base09},fg=#${colors.base01},bold]{index} #[bg=#${colors.base01},fg=#${colors.base09},bold] {name}{floating_indicator}#[bg=#${colors.base01},fg=#${colors.base01},bold]█"
                     tab_active_fullscreen   "#[bg=#${colors.base01},fg=#${colors.base09}]█#[bg=#${colors.base09},fg=#${colors.base01},bold]{index} #[bg=#${colors.base01},fg=#${colors.base09},bold] {name}{fullscreen_indicator}#[bg=#${colors.base01},fg=#${colors.base01},bold]█"
                     tab_active_sync         "#[bg=#${colors.base01},fg=#${colors.base09}]█#[bg=#${colors.base09},fg=#${colors.base01},bold]{index} #[bg=#${colors.base01},fg=#${colors.base09},bold] {name}{sync_indicator}#[bg=#${colors.base01},fg=#${colors.base01},bold]█"

                     // separator between the tabs
                     tab_separator           "#[bg=#${colors.base00}] "

                     // indicators
                     tab_sync_indicator       " "
                     tab_fullscreen_indicator " 󰊓"
                     tab_floating_indicator   " 󰹙"

                     command_git_branch_command     "git rev-parse --abbrev-ref HEAD"
                     command_git_branch_format      "#[fg=blue] {stdout} "
                     command_git_branch_interval    "10"
                     command_git_branch_rendermode  "static"

                     datetime        "#[fg=#6C7086,bold] {format} "
                     datetime_format "%A, %d %b %Y %H:%M"
                     datetime_timezone "Europe/Vienna"
                 }
             }
         }
     }
''
