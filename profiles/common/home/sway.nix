{ config, pkgs, lib, ... }: with lib;
let
  inherit (config.swarselsystems) monitors;
  eachMonitor = _name: monitor: {
    inherit (monitor) name;
    value = builtins.removeAttrs monitor [ "workspace" "name" "output" ];
  };
  eachOutput = _name: monitor: {
    inherit (monitor) name;
    value = builtins.removeAttrs monitor [ "mode" "name" "scale" "position" ];
  };
  workplaceSets = mapAttrs' eachOutput monitors;
  workplaceOutputs = map (key: getAttr key workplaceSets) (attrNames workplaceSets);
in
{
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false; # delete this line once SwayFX is fixed upstream
    package = pkgs.swayfx;
    systemd = {
      enable = true;
      xdgAutostart = true;
    };
    wrapperFeatures.gtk = true;
    config = rec {
      modifier = "Mod4";
      terminal = "kitty";
      menu = "fuzzel";
      bars = [{ command = "waybar"; }];
      keybindings =
        let
          inherit (config.wayland.windowManager.sway.config) modifier;
        in
        recursiveUpdate
          {
            "${modifier}+q" = "kill";
            "${modifier}+f" = "exec firefox";
            "${modifier}+Space" = "exec fuzzel";
            "${modifier}+Shift+Space" = "floating toggle";
            "${modifier}+e" = "exec emacsclient -nquc -a emacs -e \"(dashboard-open)\"";
            "${modifier}+Shift+m" = "exec emacsclient -nquc -a emacs -e \"(mu4e)\"";
            "${modifier}+Shift+c" = "exec emacsclient -nquc -a emacs -e \"(swarsel/open-calendar)\"";
            "${modifier}+Shift+s" = "exec \"bash ~/.dotfiles/scripts/checkspotify.sh\"";
            "${modifier}+m" = "exec \"bash ~/.dotfiles/scripts/checkspotifytui.sh\"";
            "${modifier}+x" = "exec \"bash ~/.dotfiles/scripts/checkkitty.sh\"";
            "${modifier}+d" = "exec \"bash ~/.dotfiles/scripts/checkdiscord.sh\"";
            "${modifier}+Shift+r" = "exec \"bash ~/.dotfiles/scripts/restart.sh\"";
            "${modifier}+Shift+t" = "exec \"bash ~/.dotfiles/scripts/toggle_opacity.sh\"";
            "${modifier}+Shift+F12" = "move scratchpad";
            "${modifier}+F12" = "scratchpad show";
            "${modifier}+c" = "exec qalculate-gtk";
            "${modifier}+p" = "exec pass-fuzzel";
            "${modifier}+o" = "exec pass-fuzzel-otp";
            "${modifier}+Shift+p" = "exec pass-fuzzel --type";
            "${modifier}+Shift+o" = "exec pass-fuzzel-otp --type";
            "${modifier}+Escape" = "mode $exit";
            # "${modifier}+Shift+Escape" = "exec com.github.stsdc.monitor";
            "${modifier}+Shift+Escape" = "exec kitty -o confirm_os_window_close=0 btm";
            "${modifier}+s" = "exec grim -g \"$(slurp)\" -t png - | wl-copy -t image/png";
            "${modifier}+i" = "exec \"bash ~/.dotfiles/scripts/startup.sh\"";
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
            "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
            "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
            "${modifier}+Left" = "focus left";
            "${modifier}+Right" = "focus right";
            "${modifier}+Down" = "focus down";
            "${modifier}+Up" = "focus up";
            "${modifier}+Shift+Left" = "move left 40px";
            "${modifier}+Shift+Right" = "move right 40px";
            "${modifier}+Shift+Down" = "move down 40px";
            "${modifier}+Shift+Up" = "move up 40px";
            "${modifier}+h" = "focus left";
            "${modifier}+l" = "focus right";
            "${modifier}+j" = "focus down";
            "${modifier}+k" = "focus up";
            "${modifier}+Shift+h" = "move left 40px";
            "${modifier}+Shift+l" = "move right 40px";
            "${modifier}+Shift+j" = "move down 40px";
            "${modifier}+Shift+k" = "move up 40px";
            "${modifier}+Ctrl+Shift+c" = "reload";
            "${modifier}+Shift+e" = "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'";
            "${modifier}+r" = "mode resize";
            "${modifier}+Return" = "exec kitty";
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
        };
      };
      defaultWorkspace = "workspace 1:一";
      output = mapAttrs' eachMonitor monitors;
      input = config.swarselsystems.standardinputs;
      workspaceOutputAssign = workplaceOutputs;
      startup = config.swarselsystems.startup ++ [
        { command = "kitty -T kittyterm"; }
        { command = "sleep 60; kitty -T spotifytui -o confirm_os_window_close=0 spotify_player"; }
      ];
      window = {
        border = 1;
        titlebar = false;
      };
      assigns = {
        "1:一" = [{ app_id = "firefox"; }];
      };
      floating = {
        border = 1;
        criteria = [
          { title = "^Picture-in-Picture$"; }
          { app_id = "qalculate-gtk"; }
          { app_id = "org.gnome.clocks"; }
          { app_id = "com.github.stsdc.monitor"; }
          { app_id = "blueman"; }
          { app_id = "pavucontrol"; }
          { app_id = "syncthingtray"; }
          { title = "Syncthing Tray"; }
          { app_id = "SchildiChat"; }
          { app_id = "Element"; }
          { app_id = "com.nextcloud.desktopclient.nextcloud"; }
          { app_id = "gnome-system-monitor"; }
          { title = "(?:Open|Save) (?:File|Folder|As)"; }
          { title = "^Add$"; }
          { title = "com-jgoodies-jdiskreport-JDiskReport"; }
          { app_id = "discord"; }
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
            command = "sticky enable, shadows enable";
            criteria = {
              title = "^Picture-in-Picture$";
            };
          }
          {
            command = "opacity 0.8, sticky enable, border normal, move container to scratchpad";
            criteria = {
              title = "^kittyterm$";
            };
          }
          {
            command = "opacity 0.95, sticky enable, border normal, move container to scratchpad";
            criteria = {
              title = "^spotifytui$";
            };
          }
          # {
          #   command = "resize set width 60 ppt height 60 ppt, sticky enable, move container to scratchpad";
          #   criteria = {
          #     app_id="^$";
          #     class="^$";
          # };
          # }
          {

            command = "resize set width 60 ppt height 60 ppt, sticky enable, move container to scratchpad";
            criteria = {
              class = "Spotify";
            };
          }
          {
            command = "sticky enable";
            criteria = {
              app_id = "discord";
            };
          }
          {
            command = "resize set width 60 ppt height 60 ppt, sticky enable";
            criteria = {
              class = "Element";
            };
          }
          {
            command = "resize set width 60 ppt height 60 ppt, sticky enable";
            criteria = {
              app_id = "SchildiChat";
            };
          }
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
        swayfxSettings = "
          blur enable
          blur_xray disable
          blur_passes 1
          blur_radius 1
          shadows enable
          corner_radius 2
          titlebar_separator disable
          default_dim_inactive 0.02
      ";
      in
      "
        exec_always autotiling
        set $exit \"exit: [s]leep, [p]oweroff, [r]eboot, [l]ogout\"
        mode $exit {

            bindsym --to-code {
                s exec \"systemctl suspend\", mode \"default\"
                p exec \"systemctl poweroff\"
                r exec \"systemctl reboot\"
                l exec \"swaymsg exit\"

                Return mode \"default\"
                Escape mode \"default\"
                ${modifier}+x mode \"default\"
            }
        }

        exec systemctl --user import-environment

        ${swayfxSettings}

        ";
  };
}
