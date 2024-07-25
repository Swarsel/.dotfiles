_:
{
  xdg.desktopEntries = {

    cura = {
      name = "Ultimaker Cura";
      genericName = "Cura";
      exec = "cura";
      terminal = false;
      categories = [ "Application" ];
    };

    anki = {
      name = "Anki Flashcards";
      genericName = "Anki";
      exec = "anki";
      terminal = false;
      categories = [ "Application" ];
    };

    # schlidichat = {
    #   name = "SchildiChat Matrix Client";
    #   genericName = "SchildiChat";
    #   exec = "schildichat-desktop -enable-features=UseOzonePlatform -ozone-platform=wayland --disable-gpu-driver-bug-workarounds";
    #   terminal = false;
    #   categories = [ "Application"];
    # };

    element = {
      name = "Element Matrix Client";
      genericName = "Element";
      exec = "element-desktop -enable-features=UseOzonePlatform -ozone-platform=wayland --disable-gpu-driver-bug-workarounds";
      terminal = false;
      categories = [ "Application" ];
    };

    emacsclient-newframe = {
      name = "Emacs (Client, New Frame)";
      genericName = "Emacs (Client, New Frame)";
      exec = "emacsclient -r %u";
      icon = "emacs";
      terminal = false;
      categories = [ "Development" "TextEditor" ];
    };

  };
}
