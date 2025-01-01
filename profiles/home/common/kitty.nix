_:
{
  programs.kitty = {
    enable = true;
    keybindings = { };
    settings = {
      scrollback_lines = 10000;
      enable_audio_bell = false;
      notify_on_cmd_finish = "always 20";
    };
  };
}
