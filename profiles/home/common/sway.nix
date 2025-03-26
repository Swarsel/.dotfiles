{ self, config, lib, ... }:
let
  inherit (config.swarselsystems) monitors;
  workplaceSets = lib.mapAttrs' lib.swarselsystems.eachOutput monitors;
  workplaceOutputs = map (key: lib.getAttr key workplaceSets) (lib.attrNames workplaceSets);
in
{
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false; # delete this line once SwayFX is fixed upstream
    package = lib.mkIf config.swarselsystems.isNixos null;
    systemd = {
      enable = true;
      xdgAutostart = true;
    };
    wrapperFeatures.gtk = true;
    config = rec {
      modifier = "Mod4";
      # terminal = "kitty";
      menu = "fuzzel";
      bars = [{
        command = "waybar";
        mode = "hide";
        hiddenState = "hide";
        position = "top";
        extraConfig = "modifier Mod4";
      }];
      keybindings =
        let
          inherit (config.wayland.windowManager.sway.config) modifier;
        in
        lib.recursiveUpdate
          {
            "${modifier}+q" = "kill";
            "${modifier}+f" = "exec firefox";
            "${modifier}+Shift+f" = "exec swaymsg fullscreen";
            "${modifier}+Space" = "exec fuzzel";
            "${modifier}+Shift+Space" = "floating toggle";
            "${modifier}+e" = "exec emacsclient -nquc -a emacs -e \"(dashboard-open)\"";
            "${modifier}+Shift+m" = "exec emacsclient -nquc -a emacs -e \"(mu4e)\"";
            "${modifier}+Shift+c" = "exec emacsclient -nquc -a emacs -e \"(swarsel/open-calendar)\"";
            "${modifier}+m" = "exec swaymsg workspace back_and_forth";
            "${modifier}+a" = "exec swarselcheck -s";
            "${modifier}+x" = "exec swarselcheck -k";
            "${modifier}+d" = "exec swarselcheck -d";
            "${modifier}+w" = "exec swarselcheck -e";
            "${modifier}+Shift+t" = "exec opacitytoggle";
            "${modifier}+Shift+F12" = "move scratchpad";
            "${modifier}+F12" = "scratchpad show";
            "${modifier}+c" = "exec qalculate-gtk";
            "${modifier}+p" = "exec pass-fuzzel";
            "${modifier}+o" = "exec pass-fuzzel --otp";
            "${modifier}+Shift+p" = "exec pass-fuzzel --type";
            "${modifier}+Shift+o" = "exec pass-fuzzel --otp --type";
            "${modifier}+Ctrl+p" = "exec 1password --quick-acces";
            "${modifier}+Escape" = "mode $exit";
            "${modifier}+Shift+Escape" = "exec kitty -o confirm_os_window_close=0 btm";
            "${modifier}+h" = "exec hyprpicker | wl-copy";
            "${modifier}+s" = "exec grim -g \"$(slurp)\" -t png - | wl-copy -t image/png";
            "${modifier}+Shift+s" = "exec slurp | grim -g - Pictures/Screenshots/$(date +'screenshot_%Y-%m-%d-%H%M%S.png')";
            "${modifier}+Shift+v" = "exec wf-recorder -g '$(slurp -f %o -or)' -f ~/Videos/screenrecord_$(date +%Y-%m-%d-%H%M%S).mkv";
            "${modifier}+1" = "workspace 1:一";
            "${modifier}+Shift+1" = "move container to workspace 1:一";
            "${modifier}+2" = "workspace 2:二";
            "${modifier}+Shift+2" = "move container to workspace 2:二";
            "${modifier}+3" = "workspace 3:三";
            "${modifier}+Shift+3" = "move container to workspace 3:三";
            "${modifier}+4" = "workspace 4:四";
            "${modifier}+Shift+4" = "move container to workspace 4:四";
            "${modifier}+5" = "workspace 5:五";
            "${modifier}+Shift+5" = "move container to workspace 5:五";
            "${modifier}+6" = "workspace 6:六";
            "${modifier}+Shift+6" = "move container to workspace 6:六";
            "${modifier}+7" = "workspace 7:七";
            "${modifier}+Shift+7" = "move container to workspace 7:七";
            "${modifier}+8" = "workspace 8:八";
            "${modifier}+Shift+8" = "move container to workspace 8:八";
            "${modifier}+9" = "workspace 9:九";
            "${modifier}+Shift+9" = "move container to workspace 9:九";
            "${modifier}+0" = "workspace 10:十";
            "${modifier}+Shift+0" = "move container to workspace 10:十";
            "${modifier}+Ctrl+m" = "workspace 11:M";
            "${modifier}+Ctrl+Shift+m" = "move container to workspace 11:M";
            "${modifier}+Ctrl+s" = "workspace 12:S";
            "${modifier}+Ctrl+Shift+s" = "move container to workspace 12:S";
            "${modifier}+Ctrl+e" = "workspace 13:E";
            "${modifier}+Ctrl+Shift+e" = "move container to workspace 13:E";
            "${modifier}+Ctrl+t" = "workspace 14:T";
            "${modifier}+Ctrl+Shift+t" = "move container to workspace 14:T";
            "${modifier}+Ctrl+l" = "workspace 15:L";
            "${modifier}+Ctrl+Shift+l" = "move container to workspace 15:L";
            "${modifier}+Ctrl+f" = "workspace 16:F";
            "${modifier}+Ctrl+Shift+f" = "move container to workspace 16:F";
            "${modifier}+Left" = "focus left";
            "${modifier}+Right" = "focus right";
            "${modifier}+Down" = "focus down";
            "${modifier}+Up" = "focus up";
            "${modifier}+Shift+Left" = "move left 40px";
            "${modifier}+Shift+Right" = "move right 40px";
            "${modifier}+Shift+Down" = "move down 40px";
            "${modifier}+Shift+Up" = "move up 40px";
            "${modifier}+Ctrl+Shift+c" = "reload";
            "${modifier}+Ctrl+Shift+r" = "exec swarsel-displaypower";
            "${modifier}+Shift+e" = "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'";
            "${modifier}+r" = "mode resize";
            # "${modifier}+Return" = "exec kitty";
            "${modifier}+Return" = "exec swarselzellij";
            "${modifier}+Print" = "exec screenshare";
            # exec swaymsg move workspace to "$(swaymsg -t get_outputs | jq '[.[] | select(.active == true)] | .[(map(.focused) | index(true) + 1) % length].name')"
            # "XF86AudioRaiseVolume" = "exec pa 5%";
            "XF86AudioRaiseVolume" = "exec pamixer -i 5";
            # "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
            "XF86AudioLowerVolume" = "exec pamixer -d 5";
            # "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
            "XF86AudioMute" = "exec pamixer -t";
            "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
            "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
            "XF86Display" = "exec wl-mirror eDP-1";
          }
          config.swarselsystems.keybindings;
      modes = {
        resize = {
          Down = "resize grow height 10 px or 10 ppt";
          Escape = "mode default";
          Left = "resize shrink width 10 px or 10 ppt";
          Return = "mode default";
          Right = "resize grow width 10 px or 10 ppt";
          Up = "resize shrink height 10 px or 10 ppt";
          Tab = "move position center, resize set width 50 ppt height 50 ppt";
        };
      };
      defaultWorkspace = "workspace 1:一";
      # output = lib.mapAttrs' lib.swarselsystems.eachMonitor monitors;
      output = {
        "${config.swarselsystems.sharescreen}" = {
          bg = "${self}/wallpaper/lenovowp.png ${config.stylix.imageScalingMode}";
        };
        "Philips Consumer Electronics Company PHL BDM3270 AU11806002320" = {
          bg = "${self}/wallpaper/standwp.png ${config.stylix.imageScalingMode}";
        };
      };
      input = config.swarselsystems.standardinputs;
      workspaceOutputAssign = workplaceOutputs;
      startup = config.swarselsystems.startup ++ [
        { command = "kitty -T kittyterm -o confirm_os_window_close=0 zellij attach --create kittyterm"; }
        { command = "sleep 60; kitty -T spotifytui -o confirm_os_window_close=0 spotify_player"; }
      ];
      seat = {
        "*" = {
          hide_cursor = "when-typing enable";
        };
      };
      window = {
        border = 1;
        titlebar = false;
      };
      assigns = {
        "15:L" = [{ app_id = "teams-for-linux"; }];
      };
      floating = {
        border = 1;
        criteria = [
          { app_id = "qalculate-gtk"; }
          { app_id = "blueman"; }
          { app_id = "pavucontrol"; }
          { app_id = "syncthingtray"; }
          { app_id = "Element"; }
          { class = "1Password"; }
          { app_id = "com.nextcloud.desktopclient.nextcloud"; }
          { title = "(?:Open|Save) (?:File|Folder|As)"; }
          { title = "^Add$"; }
          { title = "^Picture-in-Picture$"; }
          { title = "Syncthing Tray"; }
          { title = "^spotifytui$"; }
          { title = "^kittyterm$"; }
          { app_id = "vesktop"; }
          { window_role = "pop-up"; }
          { window_role = "bubble"; }
          { window_role = "dialog"; }
          { window_role = "task_dialog"; }
          { window_role = "menu"; }
          { window_role = "Preferences"; }
        ];
        titlebar = false;
      };
      window = {
        commands = [
          {
            command = "opacity 0.95";
            criteria = {
              class = ".*";
            };
          }
          {
            command = "opacity 1";
            criteria = {
              app_id = "at.yrlf.wl_mirror";
            };
          }
          {
            command = "opacity 1";
            criteria = {
              app_id = "Gimp-2.10";
            };
          }
          {
            command = "opacity 0.99";
            criteria = {
              app_id = "firefox";
            };
          }
          {
            command = "opacity 0.99";
            criteria = {
              app_id = "chromium-browser";
            };
          }
          {
            command = "sticky enable, shadows enable";
            criteria = {
              title = "^Picture-in-Picture$";
            };
          }
          {
            command = "resize set width 60 ppt height 60 ppt, opacity 0.8, sticky enable, border normal, move container to scratchpad";
            criteria = {
              title = "^kittyterm$";
            };
          }
          {
            command = "resize set width 60 ppt height 60 ppt, opacity 0.95, sticky enable, border normal, move container to scratchpad";
            criteria = {
              title = "^spotifytui$";
            };
          }
          {

            command = "resize set width 60 ppt height 60 ppt, sticky enable, move container to scratchpad";
            criteria = {
              class = "Spotify";
            };
          }
          {
            command = "resize set width 60 ppt height 60 ppt, sticky enable";
            criteria = {
              app_id = "vesktop";
            };
          }
          {
            command = "resize set width 60 ppt height 60 ppt, sticky enable";
            criteria = {
              class = "Element";
            };
          }
          # {
          #   command = "resize set width 60 ppt height 60 ppt, sticky enable, move container to scratchpad";
          #   criteria = {
          #     app_id="^$";
          #     class="^$";
          # };
          # }
        ];
      };
      gaps = {
        inner = 5;
      };
    };
    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export _JAVA_AWT_WM_NONREPARENTING=1
      export XDG_CURRENT_DESKTOP=sway
      export XDG_SESSION_DESKTOP=sway
      export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox";
      export ANKI_WAYLAND=1;
      export OBSIDIAN_USE_WAYLAND=1;
    '';
    # extraConfigEarly = "
    # exec systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK
    # exec hash dbus-update-activation-environment 2>/dev/null && dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK
    # ";
    extraConfig =
      let
        inherit (config.wayland.windowManager.sway.config) modifier;
        swayfxSettings = config.swarselsystems.swayfxConfig;
      in
      "
              exec_always autotiling
              set $exit \"exit: [s]leep, [l]ock, [p]oweroff, [r]eboot, [u]ser logout\"

              mode $exit {
                bindsym --to-code {
                  s exec \"systemctl suspend\", mode \"default\"
                  h exec \"systemctl hibernate\", mode \"default\"
                  l exec \"swaylock --screenshots --clock --effect-blur 7x5 --effect-vignette 0.5:0.5 --fade-in 0.2 --daemonize\", mode \"default\
                  p exec \"systemctl poweroff\"
                  r exec \"systemctl reboot\"
                  u exec \"swaymsg exit\"

                  Return mode \"default\"
                  Escape mode \"default\"
                  ${modifier}+Escape mode \"default\"
                }
              }

              exec systemctl --user import-environment
              exec swayidle -w

              seat * hide_cursor 2000

              exec kanshi
              exec_always kill -1 $(pidof kanshi)

              bindswitch --locked lid:on exec kanshictl switch lidclosed
              bindswitch --locked lid:off exec kanshictl switch lidopen

              ${swayfxSettings}
              ";
  };
}
