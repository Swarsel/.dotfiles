{
  flake.modules.homeManager.desktop = {
    config = {
      swarselsystems.enabledHomeModules = [ "desktop" ];
      xdg = {
        configFile."mimeapps.list".force = true;
        mimeApps = {
          enable = true;
          associations = {
            added = {
              "application/epub+zip" = [ "calibre-ebook-viewer.desktop" ];
              "application/x-zerosize" = [ "emacsclient.desktop" ];
            };
          };
          defaultApplications = {
            "application/epub+zip" = [ "calibre-ebook-viewer.desktop" ];
            "application/metalink+xml" = [ "emacsclient.desktop" ];
            "application/msword" = [ "writer.desktop" ];
            "application/pdf" = [ "org.gnome.Evince.desktop" ];
            "application/sql" = [ "emacsclient.desktop" ];
            "application/vnd.ms-excel" = [ "calc.desktop" ];
            "application/vnd.ms-powerpoint" = [ "impress.desktop" ];
            "application/x-extension-htm" = [ "glide.desktop" ];
            "application/x-extension-html" = [ "glide.desktop" ];
            "application/x-extension-shtml" = [ "glide.desktop" ];
            "application/x-extension-xht" = [ "glide.desktop" ];
            "application/x-extension-xhtml" = [ "glide.desktop" ];
            "application/xhtml+xml" = [ "glide.desktop" ];
            "audio/flac" = [ "mpv.desktop" ];
            "audio/mp3" = [ "mpv.desktop" ];
            "audio/ogg" = [ "mpv.desktop" ];
            "audio/wav" = [ "mpv.desktop" ];
            "image/gif" = [ "imv.desktop" ];
            "image/jpeg" = [ "imv.desktop" ];
            "image/png" = [ "imv.desktop" ];
            "image/svg" = [ "imv.desktop" ];
            "image/vnd.adobe.photoshop" = [ "gimp.desktop" ];
            "image/vnd.dxf" = [ "org.inkscape.Inkscape.desktop" ];
            "image/webp" = [ "glide.desktop" ];
            "text/csv" = [ "emacsclient.desktop" ];
            "text/html" = [ "glide.desktop" ];
            "text/plain" = [ "emacsclient.desktop" ];
            "video/3gp" = [ "umpv.desktop" ];
            "video/flv" = [ "umpv.desktop" ];
            "video/mkv" = [ "umpv.desktop" ];
            "video/mp4" = [ "umpv.desktop" ];
            "x-scheme-handler/chrome" = [ "glide.desktop" ];
            "x-scheme-handler/firezone-fd0020211111" = [ "firezone-client-gui-deep-link.desktop" ];
            "x-scheme-handler/http" = [ "glide.desktop" ];
            "x-scheme-handler/https" = [ "glide.desktop" ];
          };
        };
      };
      xdg.desktopEntries = {

        anki = {
          categories = [ "Application" ];
          exec = "anki";
          genericName = "Anki";
          name = "Anki Flashcards";
          terminal = false;
        };
        cura = {
          categories = [ "Application" ];
          exec = "cura";
          genericName = "Cura";
          name = "Ultimaker Cura";
          terminal = false;
        };
        element = {
          categories = [ "Application" ];
          exec = "element-desktop -enable-features=UseOzonePlatform -ozone-platform=wayland --disable-gpu-driver-bug-workarounds";
          genericName = "Element";
          name = "Element Matrix Client";
          terminal = false;
        };
        emacsclient-newframe = {
          categories = [
            "Development"
            "TextEditor"
          ];
          exec = "emacsclient -r %u";
          genericName = "Emacs (Client, New Frame)";
          icon = "emacs";
          name = "Emacs (Client, New Frame)";
          terminal = false;
        };
        rustdesk-vbc = {
          categories = [ "Application" ];
          exec = "rustdesk-vbc";
          genericName = "rustdesk-vbc";
          name = "Rustdesk VBC";
          terminal = false;
        };
        teamsNoGpu = {
          categories = [ "Application" ];
          exec = "teams-for-linux --disableGpu=true --trayIconEnabled=true";
          genericName = "Teams (no GPU)";
          name = "Microsoft Teams (no GPU)";
          terminal = false;
        };

      };
    };
  };
}
