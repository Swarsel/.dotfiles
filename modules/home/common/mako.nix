_:
{
  services.mako = {
    enable = true;
    # backgroundColor = "#2e3440";
    # borderColor = "#88c0d0";
    borderRadius = 15;
    borderSize = 1;
    defaultTimeout = 5000;
    height = 150;
    icons = true;
    ignoreTimeout = true;
    layer = "overlay";
    maxIconSize = 64;
    sort = "-time";
    width = 300;
    # font = "monospace 10";
    extraConfig = ''
      [urgency=low]
      border-color=#cccccc
      [urgency=normal]
      border-color=#d08770
      [urgency=high]
      border-color=#bf616a
      default-timeout=3000
      [category=mpd]
      default-timeout=2000
      group-by=category
    '';
  };

  services.swayosd = {
    enable = true;
    topMargin = 0.5;
  };

}
