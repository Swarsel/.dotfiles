{ lib, config, ... }:
{
  options.swarselmodules.kitty = lib.mkEnableOption "kitty settings";
  config = lib.mkIf config.swarselmodules.kitty {
    programs.kitty = {
      enable = true;
      keybindings = { };
      settings = {
        scrollback_lines = 10000;
        enable_audio_bell = false;
        notify_on_cmd_finish = "always 20";
      };
    };
  };
}
