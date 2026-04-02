{ lib, config, ... }:
{
  options.swarselmodules.kitty = lib.mkEnableOption "kitty settings";
  config = lib.mkIf config.swarselmodules.kitty {
    programs.kitty = {
      enable = true;
      keybindings =
        let
          bindWithModifier = lib.mapAttrs' (key: lib.nameValuePair ("ctrl+shift" + key));
        in
        bindWithModifier {
          "page_up" = "scroll_page_up";
          "up" = "scroll_page_up";
          "page_down" = "scroll_page_down";
          "down" = "scroll_page_down";
          "w" = "no_op";
        };
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
}
