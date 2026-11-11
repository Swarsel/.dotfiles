{
  flake.modules.homeManager.zellij =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.lib.stylix) colors;

      zellij-delete-if-idle = pkgs.writeShellApplication {
        name = "zellij-delete-if-idle";
        runtimeInputs = [
          config.programs.zellij.finalPackage
          pkgs.procps
        ];
        text = ''
          server=$1
          shells=$(pgrep -d, -P "$server")
          if ps -o comm= -p "$shells" | grep -vqxE 'zsh|bash' || pgrep -P "$shells" | grep -vqxF "$$"; then
            exit 0
          fi
          zellij delete-session --force "$(basename "$(tr '\0' '\n' <"/proc/$server/cmdline" | sed -n 3p)")" || kill "$server"
        '';
      };
      zellij-kitty = pkgs.writeShellApplication {
        name = "zellij-kitty";
        runtimeInputs = [
          config.programs.zellij.finalPackage
          pkgs.procps
          zellij-delete-if-idle
        ];
        text = ''
          tag="$$-$RANDOM"
          hup=0
          trap 'hup=1' HUP
          ZELLIJ_KITTY_TAG="$tag" zellij "$@" || true
          if [ "$hup" = 0 ]; then
            exit 0
          fi
          exec >/dev/null 2>&1
          for server in $(pgrep -f 'zellij --server'); do
            grep -qxzF "ZELLIJ_KITTY_TAG=$tag" "/proc/$server/environ" || continue
            zellij-delete-if-idle "$server"
          done
        '';
      };
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "zellij" ];
        programs = {
          kitty.settings.shell = lib.getExe zellij-kitty;
          zellij = {
            enable = true;
            enableZshIntegration = false;
            settings = {
              copy_command = if pkgs.stdenv.hostPlatform.isDarwin then "pbcopy" else "wl-copy";
              copy_on_select = true;
              default_layout = "swarsel";
              default_shell = "zsh";
              on_force_close = "detach";
              pane_frames = false;
              scrollback_lines_to_serialize = config.programs.kitty.settings.scrollback_lines;
              session_serialization = true;
              show_startup_tips = false;
              ui.pane_frames = {
                hide_session_name = true;
                rounded_corners = true;
              };
            };
          };
          zsh.initContent = ''
            if [[ -n $ZELLIJ ]]; then
              export ZELLIJ_SERVER_PID=''${ZELLIJ_SERVER_PID:-$PPID}
              zellij_tab_name=/
              zellij-tab-name() {
                [[ $1 == $zellij_tab_name ]] && return
                zellij_tab_name=$1
                {
                  local tab=$(zellij action list-panes -tj | ${lib.getExe pkgs.jq} --argjson pane $ZELLIJ_PANE_ID '.[] | select((.is_plugin | not) and .id == $pane) | .tab_id')
                  if [[ -n $1 ]]; then
                    zellij action rename-tab --tab-id $tab $1
                  else
                    zellij action undo-rename-tab --tab-id $tab
                  fi
                } &>/dev/null &!
              }
              zellij-git-tab-name() {
                zellij-tab-name ''${$(git rev-parse --show-toplevel 2>/dev/null):t}
              }
              precmd_functions+=(zellij-git-tab-name)
              ssh() {
                zellij-tab-name $(command ssh -G "$@" 2>/dev/null | sed -n 's/^host //p')
                command ssh "$@"
                local ret=$?
                if [[ -z $(zellij action list-clients | tail -n +2) ]]; then
                  ${lib.getExe zellij-delete-if-idle} "$ZELLIJ_SERVER_PID"
                fi
                return $ret
              }
            fi
          '';
        };
        home.activation.zellijPluginPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          cache="${config.xdg.cacheHome}/zellij/permissions.kdl"
          plugin="${config.xdg.dataHome}/zellij/plugins/zjstatus.wasm"
          if ! grep -qsF "\"$plugin\"" "$cache"; then
            run mkdir -p "$(dirname "$cache")"
            run sh -c 'printf "\"%s\" {\n    RunCommands\n    ReadApplicationState\n    ChangeApplicationState\n}\n" "$1" >> "$2"' _ "$plugin" "$cache"
          fi
        '';
        xdg = {
          configFile."zellij/layouts/swarsel.kdl".text = ''
            layout {
                   default_tab_template {
                       children
                       pane size=1 borderless=true {
                           plugin location="file://${config.xdg.dataHome}/zellij/plugins/zjstatus.wasm" {
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

                               datetime        "#[fg=#6C7086,bold] {format} "
                               datetime_format "%A, %d %b %Y %H:%M"
                               datetime_timezone "Europe/Vienna"
                           }
                       }
                   }
               }
          '';
          dataFile."zellij/plugins/zjstatus.wasm".source = "${pkgs.zjstatus}/bin/zjstatus.wasm";
        };
      };
    };
}
