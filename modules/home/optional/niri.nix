{ inputs, config, pkgs, lib, vars, type, ... }:
{
  imports = lib.optionals (type != "nixos") [
    inputs.niri-flake.homeModules.niri
  ];
  config = {
    programs.niri = {
      package = pkgs.niri-stable; # which package to use for niri validation
      settings = {
        debug = {
          honor-xdg-activation-with-invalid-serial = [ ];
        };
        xwayland-satellite = {
          enable = true;
          path = "${lib.getExe pkgs.xwayland-satellite-unstable}";
        };
        prefer-no-csd = true;
        layer-rules = [
          { matches = [{ namespace = "^notifications$"; }]; block-out-from = "screen-capture"; }
          { matches = [{ namespace = "^wallpaper$"; }]; place-within-backdrop = true; }
          { matches = [{ namespace = "^noctalia-overview*"; }]; place-within-backdrop = true; }
        ];
        window-rules = [
          {
            matches = [{ app-id = ".*"; }];
            opacity = 0.95;
            default-column-width = { proportion = 0.5; };
            shadow = {
              enable = true;
              draw-behind-window = true;
            };
            clip-to-geometry = true;
            geometry-corner-radius = { top-left = 5.0; top-right = 5.0; bottom-left = 5.0; bottom-right = 5.0; };
          }
          { matches = [{ app-id = "at.yrlf.wl_mirror"; }]; opacity = 1.0; }
          { matches = [{ app-id = "Gimp"; }]; opacity = 1.0; }
          { matches = [{ app-id = "^firefox$"; }]; opacity = 0.95; }
          { matches = [{ app-id = "^special.*"; }]; default-column-width = { proportion = 0.9; }; open-on-workspace = "Scratchpad"; }
          { matches = [{ app-id = "chromium-browser"; }]; opacity = 0.99; }
          { matches = [{ app-id = "^qalculate-gtk$"; }]; open-floating = true; }
          { matches = [{ app-id = "^blueman$"; }]; open-floating = true; }
          { matches = [{ app-id = "^pavucontrol$"; }]; open-floating = true; }
          { matches = [{ app-id = "^syncthingtray$"; }]; open-floating = true; }
          { matches = [{ app-id = "^Element$"; }]; open-floating = true; default-column-width = { proportion = 0.5; }; block-out-from = "screen-capture"; }
          # { matches = [{ app-id = "^Element$"; }]; default-column-width = { proportion = 0.9; }; open-on-workspace = "Scratchpad"; block-out-from = "screencast"; }
          { matches = [{ app-id = "^vesktop$"; }]; open-floating = true; default-column-width = { proportion = 0.5; }; block-out-from = "screen-capture"; }
          # { matches = [{ app-id = "^vesktop$"; }]; default-column-width = { proportion = 0.9; }; open-on-workspace = "Scratchpad"; block-out-from = "screencast"; }
          { matches = [{ app-id = "^com.nextcloud.desktopclient.nextcloud$"; }]; open-floating = true; }
          { matches = [{ title = ".*1Password.*"; }]; excludes = [{ app-id = "^firefox$"; } { app-id = "^emacs$"; } { app-id = "^kitty$"; }]; open-floating = true; block-out-from = "screen-capture"; }
          { matches = [{ title = "(?:Open|Save) (?:File|Folder|As)"; }]; open-floating = true; }
          { matches = [{ title = "^Add$"; }]; open-floating = true; }
          { matches = [{ title = "^Picture-in-Picture$"; }]; open-floating = true; }
          { matches = [{ title = "Syncthing Tray"; }]; open-floating = true; }
          { matches = [{ title = "^Emacs Popup Frame$"; }]; open-floating = true; }
          { matches = [{ title = "^Emacs Popup Anchor$"; }]; open-floating = true; }
          { matches = [{ app-id = "^spotifytui$"; }]; open-floating = true; default-column-width = { proportion = 0.5; }; }
          { matches = [{ app-id = "^kittyterm$"; }]; open-floating = true; default-column-width = { proportion = 0.5; }; }
        ];
        environment = {
          DISPLAY = ":0";
          QT_QPA_PLATFORM = lib.mkForce "wayland";
          EDITOR = "emacsclient -c";
        } // vars.waylandSessionVariables;
        screenshot-path = "~/Pictures/Screenshots/screenshot_%Y-%m-%d-%H%M%S.png";
        input = {
          mod-key = "Super";
          keyboard = {
            xkb = {
              layout = "us";
              variant = "altgr-intl";
            };
          };
          mouse = {
            natural-scroll = false;
          };
          touchpad = {
            enable = true;
            tap = true;
            tap-button-map = "left-right-middle";
            natural-scroll = true;
            scroll-method = "two-finger";
            click-method = "clickfinger";
            disabled-on-external-mouse = true;
            drag = true;
            drag-lock = false;
            dwt = true;
            dwtp = true;
          };
        };
        cursor = {
          hide-after-inactive-ms = 2000;
          hide-when-typing = true;
        };
        layout = {
          background-color = "transparent";
          border = {
            enable = true;
            width = 1;
          };
          focus-ring = {
            enable = false;
          };
          gaps = 5;
        };
        binds = with config.lib.niri.actions; let
          sh = spawn "sh" "-c";
          resizer = "niri-resize";
        in
        {
          "Mod+Shift+t".action = toggle-window-rule-opacity;
          "Mod+m".action = focus-workspace-previous;
          "Mod+Shift+Space".action = toggle-window-floating;
          "Mod+Shift+f".action = fullscreen-window;
          "Mod+q".action = sh "niri msg action close-window & ${resizer}";
          "Mod+f".action = sh "${resizer} & firefox";
          # "Mod+Space".action = spawn "noctalia-shell" "ipc" "call" "launcher" "toggle";
          "Mod+Space".action = sh "${resizer} & fuzzel";
          "Mod+z".action = spawn "noctalia-shell" "ipc" "call" "bar" "toggle";
          "Mod+Shift+c".action = spawn "qalculate-gtk";
          "Mod+Ctrl+p".action = spawn "1password" "--quick-acces";
          "Mod+Shift+Escape".action = spawn "kitty" "-o" "confirm_os_window_close=0" "btm";
          "Mod+h".action = sh ''hyprpicker | wl-copy'';
          # "Mod+s".action = spawn "grim" "-g" "\"$(slurp)\"" "-t" "png" "-" "|" "wl-copy" "-t" "image/png";
          # "Mod+s".action = screenshot { show-pointer = false; };
          "Mod+s".action.screenshot = { show-pointer = false; };
          # "Mod+Shift+s".action = spawn "slurp" "|" "grim" "-g" "-" "Pictures/Screenshots/$(date +'screenshot_%Y-%m-%d-%H%M%S.png')";
          # "Mod+Shift+s".action = screenshot-window { write-to-disk = true; };
          "Mod+Shift+s".action.screenshot-window = { write-to-disk = true; };
          # "Mod+Shift+v".action = spawn "wf-recorder" "-g" "'$(slurp -f %o -or)'" "-f" "~/Videos/screenrecord_$(date +%Y-%m-%d-%H%M%S).mkv";

          "Mod+e".action = sh "${resizer} & emacsclient -nquc -a emacs -e '(dashboard-open)'";
          "Mod+c".action = sh "${resizer} & emacsclient -ce '(org-capture)'";
          "Mod+t".action = sh "${resizer} & emacsclient -ce '(org-agenda)'";
          "Mod+Shift+m".action = sh "${resizer} & emacsclient -ce '(mu4e)'";
          "Mod+Shift+a".action = sh "${resizer} & emacsclient -ce '(swarsel/open-calendar)'";

          "Mod+a".action = spawn "swarselcheck-niri" "-s";
          "Mod+x".action = spawn "swarselcheck-niri" "-k";
          "Mod+d".action = spawn "swarselcheck-niri" "-d";
          "Mod+w".action = spawn "swarselcheck-niri" "-e";

          "Mod+p".action = spawn "pass-fuzzel";
          "Mod+o".action = spawn "pass-fuzzel" "--otp";
          "Mod+Shift+p".action = spawn "pass-fuzzel" "--type";
          "Mod+Shift+o".action = spawn "pass-fuzzel" "--otp" "--type";

          "Mod+Left".action = focus-column-or-monitor-left;
          "Mod+Right".action = focus-column-or-monitor-right;
          "Mod+Down".action = focus-window-or-workspace-down;
          "Mod+Up".action = focus-window-or-workspace-up;
          "Mod+Shift+Left".action = move-column-left;
          "Mod+Shift+Right".action = move-column-right;
          "Mod+Shift+Down".action = move-window-down-or-to-workspace-down;
          "Mod+Shift+Up".action = move-window-up-or-to-workspace-up;
          # "Mod+Ctrl+Shift+c".action = "reload";
          # "Mod+Ctrl+Shift+r".action = "exec swarsel-displaypower";
          # "Mod+Shift+e".action = "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'";
          # "Mod+r".action = "mode resize";
          # "Mod+Return".action = "exec kitty";
          "Mod+Return".action = sh "${resizer} & exec kitty -o confirm_os_window_close=0";
          "XF86AudioRaiseVolume".action = spawn "noctalia-shell" "ipc" "call" "volume" "increase";
          "XF86AudioLowerVolume".action = spawn "noctalia-shell" "ipc" "call" "volume" "decrease";
          "XF86AudioMute".action = spawn "noctalia-shell" "ipc" "call" "volume" "muteOutput";
          "XF86AudioPrev".action = spawn "noctalia-shell" "ipc" "call" "media" "previous";
          "XF86AudioPlay".action = spawn "noctalia-shell" "ipc" "call" "media" "playPause";
          "XF86AudioNext".action = spawn "noctalia-shell" "ipc" "call" "media" "next";
          "XF86MonBrightnessUp".action = spawn "noctalia-shell" "ipc" "call" "brightness" "increase";
          "XF86MonBrightnessDown".action = spawn "noctalia-shell" "ipc" "call" "brightness" "decrease";
          "XF86Display".action = spawn "wl-mirror" "eDP-1";
          "Mod+Escape".action = spawn "noctalia-shell" "ipc" "call" "sessionMenu" "toggle";
          "Mod+i".action = spawn "noctalia-shell" "ipc" "call" "launcher" "emoji";
          "Mod+Equal".action = set-column-width "+10%";
          "Mod+Minus".action = set-column-width "-10%";

          "Mod+1".action = focus-workspace 1;
          "Mod+2".action = focus-workspace 2;
          "Mod+3".action = focus-workspace 3;
          "Mod+4".action = focus-workspace 4;
          "Mod+5".action = focus-workspace 5;
          "Mod+6".action = focus-workspace 6;
          "Mod+7".action = focus-workspace 7;
          "Mod+8".action = focus-workspace 8;
          "Mod+9".action = focus-workspace 9;
          "Mod+0".action = focus-workspace 0;

          "Mod+Shift+1".action = move-column-to-index 1;
          "Mod+Shift+2".action = move-column-to-index 2;
          "Mod+Shift+3".action = move-column-to-index 3;
          "Mod+Shift+4".action = move-column-to-index 4;
          "Mod+Shift+5".action = move-column-to-index 5;
          "Mod+Shift+6".action = move-column-to-index 6;
          "Mod+Shift+7".action = move-column-to-index 7;
          "Mod+Shift+8".action = move-column-to-index 8;
          "Mod+Shift+9".action = move-column-to-index 9;
          "Mod+Shift+0".action = move-column-to-index 0;
        };
        spawn-at-startup = [
          # { command = [ "vesktop" "--start-minimized" "--enable-speech-dispatcher" "--ozone-platform-hint=auto" "--enable-features=WaylandWindowDecorations" "--enable-wayland-ime" ]; }
          # { command = [ "element-desktop" "--hidden" "--enable-features=UseOzonePlatform" "--ozone-platform=wayland" "--disable-gpu-driver-bug-workarounds" ]; }
          # { command = [ "anki" ]; }
          # { command = [ "obsidian" ]; }
          # { command = [ "nm-applet" ]; }
          # { command = [ "niri" "msg" "action" "focus-workspace" "2" ]; }
          # { command = [ "noctalia-shell" ]; }
          { command = [ "pkill mako" ]; }
          { command = [ "systemctl" "--user" "start" "noctalia-shell.target" ]; }
        ];
        # workspaces = {
        # "01-Main" = {
        #   name = "Scratchpad";
        # };
        #   "99-Scratchpad" = {
        #     name = "";
        #   };
        # };
      };
    };

  };
}
