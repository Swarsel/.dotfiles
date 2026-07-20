{
  flake.modules = {
    homeManager = {
      sway =
        {
          config,
          lib,
          confLib,
          vars,
          nixosConfig ? null,
          ...
        }:
        let
          eachOutput = _: monitor: {
            inherit (monitor) name;
            value = builtins.removeAttrs monitor [
              "mode"
              "name"
              "scale"
              "transform"
              "position"
            ];
          };
        in
        {
          config = {
            swarselsystems = {
              swayfxConfig = lib.mkIf (nixosConfig == null) " ";
              touchpad = lib.mkIf config.swarselsystems.isLaptop {
                "type:touchpad" = {
                  drag_lock = "disabled";
                  dwt = "enabled";
                  middle_emulation = "enabled";
                  natural_scroll = "enabled";
                  tap = "enabled";
                };
              };
            };
            swarselsystems.enabledHomeModules = [ "sway" ];
            home.sessionVariables.EDITOR = lib.mkDefault "e -w";
            wayland.windowManager.sway = {
              config = rec {
                assigns."15:L" = [ { app_id = "teams-for-linux"; } ];
                bars = [
                  {
                    command = "waybar";
                    extraConfig = "modifier Mod4";
                    hiddenState = "hide";
                    mode = "hide";
                    position = "top";
                  }
                ];
                defaultWorkspace = "workspace 1:一";
                floating = {
                  border = 1;
                  criteria = [
                    { app_id = "qalculate-gtk"; }
                    { app_id = "blueman"; }
                    { app_id = "pavucontrol"; }
                    { app_id = "syncthingtray"; }
                    { app_id = "Element"; }
                    { app_id = "1Password"; }
                    { app_id = "com.nextcloud.desktopclient.nextcloud"; }
                    { title = "(?:Open|Save) (?:File|Folder|As)"; }
                    { title = "^Add$"; }
                    { title = "^Picture-in-Picture$"; }
                    { title = "Syncthing Tray"; }
                    { title = "^Emacs Popup Frame$"; }
                    { title = "^Emacs Popup Anchor$"; }
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
                gaps.inner = 5;
                input = config.swarselsystems.standardinputs;
                keybindings =
                  let
                    inherit (config.wayland.windowManager.sway.config) modifier;
                  in
                  lib.recursiveUpdate {
                    "${modifier}+0" = "workspace 10:十";
                    "${modifier}+1" = "workspace 1:一";
                    "${modifier}+2" = "workspace 2:二";
                    "${modifier}+3" = "workspace 3:三";
                    "${modifier}+4" = "workspace 4:四";
                    "${modifier}+5" = "workspace 5:五";
                    "${modifier}+6" = "workspace 6:六";
                    "${modifier}+7" = "workspace 7:七";
                    "${modifier}+8" = "workspace 8:八";
                    "${modifier}+9" = "workspace 9:九";
                    "${modifier}+Ctrl+Shift+c" = "reload";
                    "${modifier}+Ctrl+Shift+e" = "move container to workspace 13:E";
                    "${modifier}+Ctrl+Shift+f" = "move container to workspace 16:F";
                    "${modifier}+Ctrl+Shift+l" = "move container to workspace 15:L";
                    "${modifier}+Ctrl+Shift+m" = "move container to workspace 11:M";
                    "${modifier}+Ctrl+Shift+r" = "exec swarsel-displaypower";
                    "${modifier}+Ctrl+Shift+s" = "move container to workspace 12:S";
                    "${modifier}+Ctrl+Shift+t" = "move container to workspace 14:T";
                    "${modifier}+Ctrl+e" = "workspace 13:E";
                    "${modifier}+Ctrl+f" = "workspace 16:F";
                    "${modifier}+Ctrl+l" = "workspace 15:L";
                    "${modifier}+Ctrl+m" = "workspace 11:M";
                    "${modifier}+Ctrl+p" = "exec 1password --quick-acces";
                    "${modifier}+Ctrl+s" = "workspace 12:S";
                    "${modifier}+Ctrl+t" = "workspace 14:T";
                    "${modifier}+Down" = "focus down";
                    "${modifier}+Escape" = "exec wlogout";
                    "${modifier}+F12" = "scratchpad show";
                    "${modifier}+Left" = "focus left";
                    "${modifier}+Return" = "exec swarselzellij";
                    "${modifier}+Right" = "focus right";
                    "${modifier}+Shift+0" = "move container to workspace 10:十";
                    "${modifier}+Shift+1" = "move container to workspace 1:一";
                    "${modifier}+Shift+2" = "move container to workspace 2:二";
                    "${modifier}+Shift+3" = "move container to workspace 3:三";
                    "${modifier}+Shift+4" = "move container to workspace 4:四";
                    "${modifier}+Shift+5" = "move container to workspace 5:五";
                    "${modifier}+Shift+6" = "move container to workspace 6:六";
                    "${modifier}+Shift+7" = "move container to workspace 7:七";
                    "${modifier}+Shift+8" = "move container to workspace 8:八";
                    "${modifier}+Shift+9" = "move container to workspace 9:九";
                    "${modifier}+Shift+Down" = "move down 40px";
                    "${modifier}+Shift+Escape" = "exec kitty -o confirm_os_window_close=0 btm";
                    "${modifier}+Shift+F12" = "move scratchpad";
                    "${modifier}+Shift+Left" = "move left 40px";
                    "${modifier}+Shift+Right" = "move right 40px";
                    "${modifier}+Shift+Space" = "floating toggle";
                    "${modifier}+Shift+Up" = "move up 40px";
                    "${modifier}+Shift+a" =
                      "exec emacsclient -cF '((name . \"Emacs Popup Anchor\"))' -e '(prot-window-popup-swarsel/open-calendar)'";
                    "${modifier}+Shift+c" = "exec qalculate-gtk";
                    "${modifier}+Shift+e" =
                      "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'";
                    "${modifier}+Shift+f" = "exec swaymsg fullscreen";
                    "${modifier}+Shift+m" =
                      "exec emacsclient -cF '((name . \"Emacs Popup Anchor\"))' -e '(prot-window-popup-mu4e)'";
                    "${modifier}+Shift+o" = "exec pass-fuzzel --otp --type";
                    "${modifier}+Shift+p" = "exec pass-fuzzel --type";
                    "${modifier}+Shift+s" =
                      "exec slurp | grim -g - Pictures/Screenshots/$(date +'screenshot_%Y-%m-%d-%H%M%S.png')";
                    "${modifier}+Shift+t" = "exec opacitytoggle";
                    "${modifier}+Shift+v" =
                      "exec wf-recorder -g '$(slurp -f %o -or)' -f ~/Videos/screenrecord_$(date +%Y-%m-%d-%H%M%S).mkv";
                    "${modifier}+Space" = "exec fuzzel";
                    "${modifier}+Up" = "focus up";
                    "${modifier}+a" = "exec swarselcheck -s";
                    "${modifier}+c" =
                      "exec emacsclient -cF '((name . \"Emacs Popup Anchor\"))' -e '(prot-window-popup-org-capture)'";
                    "${modifier}+d" = "exec swarselcheck -d";
                    "${modifier}+e" = "exec emacsclient -nquc -a emacs -e \"(dashboard-open)\"";
                    "${modifier}+f" = "exec glide";
                    "${modifier}+h" = "exec hyprpicker | wl-copy";
                    "${modifier}+m" = "exec swaymsg workspace back_and_forth";
                    "${modifier}+o" = "exec pass-fuzzel --otp";
                    "${modifier}+p" = "exec pass-fuzzel";
                    "${modifier}+q" = "kill";
                    "${modifier}+r" = "mode resize";
                    "${modifier}+s" = "exec grim -g \"$(slurp)\" -t png - | wl-copy -t image/png";
                    "${modifier}+t" =
                      "exec emacsclient -cF '((name . \"Emacs Popup Anchor\"))' -e '(prot-window-popup-org-agenda)'";
                    "${modifier}+w" = "exec swarselcheck -e";
                    "${modifier}+x" = "exec swarselcheck -k";
                    "XF86AudioLowerVolume" = "exec swayosd-client --output-volume lower";
                    "XF86AudioMute" = "exec swayosd-client --output-volume mute-toggle";
                    # "${modifier}+Escape" = "mode $exit";
                    # "${modifier}+Return" = "exec kitty";
                    "XF86AudioRaiseVolume" = "exec swayosd-client --output-volume raise";
                    "XF86Display" = "exec wl-mirror eDP-1";
                    "XF86MonBrightnessDown" = "exec swayosd-client --brightness lower";
                    "XF86MonBrightnessUp" = "exec swayosd-client --brightness raise";
                    # "--no-repeat Super_L" = "exec killall -SIGUSR1 .waybar-wrapped";
                    # "${modifier}+z" = "exec killall -SIGUSR1 .waybar-wrapped";
                  } config.swarselsystems.keybindings;
                # terminal = "kitty";
                menu = "fuzzel";
                modes.resize = {
                  Down = "resize grow height 10 px or 10 ppt";
                  Escape = "mode default";
                  Left = "resize shrink width 10 px or 10 ppt";
                  Return = "mode default";
                  Right = "resize grow width 10 px or 10 ppt";
                  Tab = "move position center, resize set width 50 ppt height 50 ppt";
                  Up = "resize shrink height 10 px or 10 ppt";
                };
                modifier = "Mod4";
                seat."*".hide_cursor = "when-typing enable";
                startup = config.swarselsystems.startup ++ [
                  { command = "kitty -T kittyterm -o confirm_os_window_close=0 zellij attach --create kittyterm"; }
                  { command = "sleep 60; kitty -T spotifytui -o confirm_os_window_close=0 spotify_player"; }
                  { command = "mako"; }
                ];
                window = {
                  border = 1;
                  titlebar = false;
                };
                window.commands = [
                  {
                    command = "opacity 0.95";
                    criteria.class = ".*";
                  }
                  {
                    command = "opacity 1";
                    criteria.app_id = "at.yrlf.wl_mirror";
                  }
                  {
                    command = "opacity 1";
                    criteria.app_id = "Gimp-2.10";
                  }
                  {
                    command = "opacity 0.99";
                    criteria.app_id = "firefox";
                  }
                  {
                    command = "opacity 0.99";
                    criteria.app_id = "glide";
                  }
                  {
                    command = "opacity 0.99";
                    criteria.app_id = "chromium-browser";
                  }
                  {
                    command = "sticky enable, shadows enable";
                    criteria.title = "^Picture-in-Picture$";
                  }
                  {
                    command = "resize set width 60 ppt height 60 ppt, opacity 0.99, sticky enable";
                    criteria.title = "^Emacs Popup Frame$";
                  }
                  {
                    command = "move container to scratchpad";
                    criteria.title = "^Emacs Popup Anchor$";
                  }
                  {
                    command = "resize set width 60 ppt height 60 ppt, opacity 0.8, sticky enable, border normal, move container to scratchpad";
                    criteria.title = "^kittyterm$";
                  }
                  {
                    command = "resize set width 60 ppt height 60 ppt, opacity 0.95, sticky enable, border normal, move container to scratchpad";
                    criteria.title = "^spotifytui$";
                  }
                  {

                    command = "resize set width 60 ppt height 60 ppt, sticky enable, move container to scratchpad";
                    criteria.class = "Spotify";
                  }
                  {
                    command = "resize set width 60 ppt height 60 ppt, sticky enable";
                    criteria.app_id = "vesktop";
                  }
                  {
                    command = "resize set width 60 ppt height 60 ppt, sticky enable";
                    criteria.class = "Element";
                  }
                  # {
                  #   command = "resize set width 60 ppt height 60 ppt, sticky enable, move container to scratchpad";
                  #   criteria = {
                  #     app_id="^$";
                  #     class="^$";
                  # };
                  # }
                ];
                workspaceOutputAssign =
                  let
                    workplaceSets = lib.mapAttrs' eachOutput config.swarselsystems.monitors;
                    workplaceOutputs = map (key: lib.getAttr key workplaceSets) (lib.attrNames workplaceSets);
                  in
                  workplaceOutputs;
              };
              enable = true;
              # checkConfig = false; # delete this line once SwayFX is fixed upstream
              package = lib.mkIf (nixosConfig != null) null;
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
        # exec_always autotiling
                    # set $exit \"exit: [s]leep, [l]ock, [p]oweroff, [r]eboot, [u]ser logout\"

                    # mode $exit {
                    #   bindsym --to-code {
                    #     s exec \"systemctl suspend\", mode \"default\"
                    #     h exec \"systemctl hibernate\", mode \"default\"
                    #     l exec \"swaylock --screenshots --clock --effect-blur 7x5 --effect-vignette 0.5:0.5 --fade-in 0.2 --daemonize\", mode \"default\
                    #     p exec \"systemctl poweroff\"
                    #     r exec \"systemctl reboot\"
                    #     u exec \"swaymsg exit\"

                    #     Return mode \"default\"
                    #     Escape mode \"default\"
                    #     ${modifier}+Escape mode \"default\"
                    #   }
                    # }

                    exec systemctl --user import-environment

                    seat * hide_cursor 2000

                    exec_always kill -1 $(pidof kanshi)

                    bindswitch --locked lid:on exec kanshictl switch lidclosed
                    bindswitch --locked lid:off exec kanshictl switch lidopen

                    ${
                                      swayfxSettings
                                    }
                    ";
              extraSessionCommands = ''
                export XDG_CURRENT_DESKTOP=sway;
                export XDG_SESSION_DESKTOP=sway;
                export _JAVA_AWT_WM_NONREPARENTING=1;
                export GITHUB_NOTIFICATION_TOKEN_PATH=${confLib.getConfig.sops.secrets.github-notifications-token.path};
              ''
              + vars.waylandExports;
              wrapperFeatures = {
                base = true;
                gtk = true;
              };
              systemd = {
                enable = true;
                variables = [
                  "DISPLAY"
                  "WAYLAND_DISPLAY"
                  "SWAYSOCK"
                  "XDG_CURRENT_DESKTOP"
                  "XDG_SESSION_TYPE"
                  "NIXOS_OZONE_WL"
                  "XCURSOR_THEME"
                  "XCURSOR_SIZE"
                ];
                xdgAutostart = true;
              };
            };
          };
        };

      swaylock =
        { pkgs, ... }:
        let
          moduleName = "swaylock";
        in
        {
          config = {
            swarselsystems.enabledHomeModules = [ "swaylock" ];
            programs.${moduleName} = {
              enable = true;
              package = pkgs.swaylock-effects;
              settings = {
                clock = true;
                effect-blur = "7x5";
                effect-vignette = "0.5:0.5";
                fade-in = "0.2";
                screenshots = true;
              };
            };
          };

        };
    };
    nixos.sway =
      {
        config,
        lib,
        pkgs,
        withHomeManager,
        ...
      }:
      let
        inherit (config.swarselsystems) mainUser;
      in
      {
        config = {
          programs.sway = {
            enable = true;
            package = pkgs.swayfx;
            wrapperFeatures = {
              base = true;
              gtk = true;
            };
          };
        }
        // lib.optionalAttrs withHomeManager {
          inherit (config.home-manager.users.${mainUser}.wayland.windowManager.sway) extraSessionCommands;
        };
      };
  };
}
