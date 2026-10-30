{
  flake.modules.homeManager.kitty = { lib, ... }: {
    config = {
      swarselsystems.enabledHomeModules = [ "kitty" ];
      programs.kitty = {
        enable = true;
        keybindings =
          let
            hintTargets = {
              f = "path";
              h = "hash";
              i = "ip";
              l = "line";
              u = "url";
              w = "word";
            };
            bindWithModifier = lib.mapAttrs' (key: lib.nameValuePair ("ctrl+shift+" + key));
            hint =
              prefix: program:
              lib.mapAttrs' (
                key: type: lib.nameValuePair "${prefix}>${key}" "kitten hints --type ${type} --program ${program}"
              );
            copyHint = hint "y" "@";
            pasteHint = hint "p" "-";
            disable = keys: lib.genAttrs keys (_: "no_op");
            font = mode: keys: lib.genAttrs keys (_: "change_font_size all ${mode}2.0");
          in
          disable [ "ctrl+tab" ]
          // bindWithModifier (
            {
              backspace = "change_font_size all 0";
              e = "open_url_with_hints";
              "p>n" = "kitten hints --type linenum";
              u = "kitten unicode_input";
            }
            // font "+" [
              "equal"
              "plus"
            ]
            // font "-" [
              "minus"
            ]
            // disable (
              [
                ","
                "."
                "/"
                "["
                "]"
                "`"
                "alt+t"
                "b"
                "down"
                "end"
                "enter"
                "f"
                "f7"
                "f8"
                "g"
                "h"
                "home"
                "j"
                "k"
                "l"
                "left"
                "page_down"
                "page_up"
                "q"
                "r"
                "right"
                "t"
                "tab"
                "up"
                "w"
                "x"
                "z"
              ]
              ++ map toString (lib.range 0 9)
            )
            // pasteHint hintTargets
            // copyHint hintTargets
          );
        settings = {
          cursor_blink_interval = 0;
          disable_ligatures = "cursor";
          enable_audio_bell = false;
          notify_on_cmd_finish = "always 20";
          open_url_with = "xdg-open";
          scrollback_lines = 100000;
          scrollback_pager_history_size = 512;
        };
      };
    };
  };
}
