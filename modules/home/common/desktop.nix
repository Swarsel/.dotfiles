{ lib, config, ... }:
{
  options.swarselmodules.desktop = lib.mkEnableOption "desktop settings";
  config = lib.mkIf config.swarselmodules.desktop {
    xdg.desktopEntries = {

      cura = {
        name = "Ultimaker Cura";
        genericName = "Cura";
        exec = "cura";
        terminal = false;
        categories = [ "Application" ];
      };

      teamsNoGpu = {
        name = "Microsoft Teams (no GPU)";
        genericName = "Teams (no GPU)";
        exec = "teams-for-linux --disableGpu=true --trayIconEnabled=true";
        terminal = false;
        categories = [ "Application" ];
      };

      rustdesk-vbc = {
        name = "Rustdesk VBC";
        genericName = "rustdesk-vbc";
        exec = "rustdesk-vbc";
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

    xdg.mimeApps = {

      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/chrome" = [ "firefox.desktop" ];
        "text/plain" = [ "emacsclient.desktop" ];
        "text/csv" = [ "emacsclient.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "application/x-extension-htm" = [ "firefox.desktop" ];
        "application/x-extension-html" = [ "firefox.desktop" ];
        "application/x-extension-shtml" = [ "firefox.desktop" ];
        "application/xhtml+xml" = [ "firefox.desktop" ];
        "application/x-extension-xhtml" = [ "firefox.desktop" ];
        "application/x-extension-xht" = [ "firefox.desktop" ];
        "image/png" = [ "imv.desktop" ];
        "image/jpeg" = [ "imv.desktop" ];
        "image/gif" = [ "imv.desktop" ];
        "image/svg" = [ "imv.desktop" ];
        "image/webp" = [ "firefox.desktop" ];
        "image/vnd.adobe.photoshop" = [ "gimp.desktop" ];
        "image/vnd.dxf" = [ "org.inkscape.Inkscape.desktop" ];
        "audio/flac" = [ "mpv.desktop" ];
        "audio/mp3" = [ "mpv.desktop" ];
        "audio/ogg" = [ "mpv.desktop" ];
        "audio/wav" = [ "mpv.desktop" ];
        "video/mp4" = [ "umpv.desktop" ];
        "video/mkv" = [ "umpv.desktop" ];
        "video/flv" = [ "umpv.desktop" ];
        "video/3gp" = [ "umpv.desktop" ];
        "application/pdf" = [ "org.gnome.Evince.desktop" ];
        "application/metalink+xml" = [ "emacsclient.desktop" ];
        "application/sql" = [ "emacsclient.desktop" ];
        "application/vnd.ms-powerpoint" = [ "impress.desktop" ];
        "application/msword" = [ "writer.desktop" ];
        "application/vnd.ms-excel" = [ "calc.desktop" ];
      };
      associations = {
        added = {
          "application/x-zerosize" = [ "emacsclient.desktop" ];
        };
      };
    };
  };
}
