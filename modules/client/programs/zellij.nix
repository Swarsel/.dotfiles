{
  flake.modules.homeManager.zellij =
    {
      self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.lib.stylix) colors;
      kittySequences = {
        p = {
          color = colors.base0C;
          key = "F11";
          label = "PASTE";
        };
        y = {
          color = colors.base09;
          key = "F10";
          label = "COPY";
        };
      };
      kittySequenceClearKey = "F12";
      kittySequenceSignal = key: "Ctrl Alt Shift ${key}";
      kittySequenceWatcher = pkgs.writeText "kitty-zellij-sequence.py" ''
        from kitty.fast_data_types import GLFW_MOD_ALT, GLFW_MOD_CONTROL, GLFW_MOD_SHIFT, GLFW_MOD_SUPER

        SIGNALS = ${builtins.toJSON (lib.mapAttrs (_: s: kittySequenceSignal s.key) kittySequences)}
        CLEAR = "${kittySequenceSignal kittySequenceClearKey}"
        MODS = GLFW_MOD_ALT | GLFW_MOD_CONTROL | GLFW_MOD_SHIFT | GLFW_MOD_SUPER
        shown = {"window": None, "signal": CLEAR}


        def current_signal(boss):
            stack = boss.mappings.keyboard_mode_stack
            keys = stack[-1].sequence_keys if stack else None
            if keys and keys[0].mods & MODS == GLFW_MOD_CONTROL | GLFW_MOD_SHIFT:
                return SIGNALS.get(chr(keys[0].key), CLEAR)
            return CLEAR


        def runs_zellij(window):
            return any("zellij" in " ".join(p.get("cmdline") or []) for p in window.child.foreground_processes)


        def on_tab_bar_dirty(boss, window, data):
            signal = current_signal(boss)
            if signal == shown["signal"]:
                return
            target = window if signal != CLEAR else boss.window_id_map.get(shown["window"])
            shown.update(window=window.id, signal=signal)
            if target is not None and runs_zellij(target):
                target.send_key(signal.lower().replace(" ", "+"))
      '';
      kittySequenceBind = key: payload: {
        bind = {
          _args = [ (kittySequenceSignal key) ];
          _children = [
            {
              MessagePlugin._children = [
                { name._args = [ "kittysequence" ]; }
                { payload._args = [ "zjstatus::pipe::pipe_kittysequence::${payload}" ]; }
              ];
            }
          ];
        };
      };
      zellij-kitty = pkgs.writeShellApplication {
        name = "zellij-kitty";
        runtimeInputs = [
          config.programs.zellij.finalPackage
          pkgs.procps
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
            for child in $(pgrep -P "$server"); do
              case "$(ps -o comm= -p "$child")" in
                zsh | bash)
                  if pgrep -P "$child" >/dev/null; then
                    exit 0
                  fi
                  ;;
                *) exit 0 ;;
              esac
            done
            session=$(basename "$(tr '\0' '\n' <"/proc/$server/cmdline" | sed -n 3p)")
            zellij delete-session --force "$session" || kill "$server"
          done
        '';
      };
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "zellij" ];
        programs = {
          kitty.settings = {
            shell = lib.getExe zellij-kitty;
            watcher = "${kittySequenceWatcher}";
          };
          zellij = {
            enable = true;
            enableZshIntegration = false;
            settings = {
              copy_command =
                if pkgs.stdenv.hostPlatform.isLinux then
                  "wl-copy"
                else if pkgs.stdenv.hostPlatform.isDarwin then
                  "pbcopy"
                else
                  "";
              copy_on_select = false;
              default_layout = "swarsel";
              default_shell = "zsh";
              keybinds.shared._children =
                lib.mapAttrsToList (
                  _: s:
                  kittySequenceBind s.key "#[bg=#${s.color},fg=#${colors.base01},bold] ${s.label}#[bg=#${colors.base01},fg=#${s.color}]█"
                ) kittySequences
                ++ [ (kittySequenceBind kittySequenceClearKey "") ];
              layout_dir = "${config.home.homeDirectory}/.config/zellij/layouts";
              on_force_close = "detach";
              pane_frames = false;
              scrollback_lines_to_serialize = config.programs.kitty.settings.scrollback_lines;
              session_serialization = true;
              show_startup_tips = false;
              simplified_ui = false;
              support_kitty_keyboard_protocol = true;
              theme_dir = "${config.home.homeDirectory}/.config/zellij/themes";
              ui.pane_frames = {
                hide_session_name = true;
                rounded_corners = true;
              };
            };
          };
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
          configFile."zellij/layouts/swarsel.kdl".text =
            import "${self}/files/zellij/layouts/swarsel.kdl.nix"
              {
                inherit config;
              };
          dataFile."zellij/plugins/zjstatus.wasm".source = "${pkgs.zjstatus}/bin/zjstatus.wasm";
        };
      };
    };
}
