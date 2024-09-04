{ config, lib, pkgs, ... }:
{
  programs.waybar = {

    enable = true;
    systemd = {
      enable = true;
      target = "sway-sessions.target";
    };
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        modules-left = [ "sway/workspaces" "custom/outer-right-arrow-dark" "sway/window" ];
        modules-center = [ "sway/mode" "privacy" "custom/github" "custom/configwarn" "custom/nix-updates" ];
        "sway/mode" = {
          format = "<span style=\"italic\" font-weight=\"bold\">{}</span>";
        };

        modules-right = config.swarselsystems.waybarModules;

        "custom/pseudobat" = lib.mkIf (!config.swarselsystems.isLaptop) {
          format = "";
          on-click-right = "wlogout -p layer-shell";
        };

        "custom/configwarn" = {
          exec = "waybarupdate";
          interval = 60;
        };

        "custom/scratchpad-indicator" = {
          interval = 3;
          exec = "swaymsg -t get_tree | jq 'recurse(.nodes[]) | first(select(.name==\"__i3_scratch\")) | .floating_nodes | length | select(. >= 1)'";
          format = "{} ";
          on-click = "swaymsg 'scratchpad show'";
          on-click-right = "swaymsg 'move scratchpad'";
        };

        "custom/github" = {
          format = "{}  ";
          return-type = "json";
          interval = 60;
          exec = "github-notifications";
          on-click = "xdg-open https://github.com/notifications";
        };

        # "custom/nix-updates" = {
        #   exec = "update-checker";
        #   on-click = "update-checker && notify-send 'The system has been updated'";
        #   interval = "once";
        #   tooltip = true;
        #   return-type = "json";
        #   format = "{} {icon}";
        #   format-icon = {
        #     "has-updates" = "";
        #     "updated" = " ";
        #   };
        # };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
        };

        "group/hardware" = {
          orientation = "inherit";
          drawer = {
            "transition-left-to-right" = false;
          };
          modules = [
            "tray"
            "temperature"
            "power-profiles-daemon"
            "custom/left-arrow-light"
            "custom/left-arrow-dark"
            "custom/scratchpad-indicator"
            "custom/left-arrow-light"
            "disk"
            "custom/left-arrow-dark"
            "memory"
            "custom/left-arrow-light"
            "cpu"
            "custom/left-arrow-dark"
            "backlight/slider"
            "idle_inhibitor"
          ];
        };

        "backlight/slider" = {
          min = 0;
          max = 100;
          orientation = "horizontal";
          device = "intel_backlight";
        };

        power-profiles-daemon = {
          format = "{icon}";
          tooltip-format = "Power profile: {profile}\nDriver: {driver}";
          tooltip = true;
          format-icons = {
            "default" = "";
            "performance" = "";
            "balanced" = "";
            "power-saver" = "";
          };
        };

        temperature = {
          hwmon-path = lib.mkIf (!config.swarselsystems.temperatureHwmon.isAbsolutePath) config.swarselsystems.temperatureHwmon.path;
          hwmon-path-abs = lib.mkIf config.swarselsystems.temperatureHwmon.isAbsolutePath config.swarselsystems.temperatureHwmon.path;
          input-filename = lib.mkIf config.swarselsystems.temperatureHwmon.isAbsolutePath config.swarselsystems.temperatureHwmon.input-filename;
          critical-threshold = 80;
          format-critical = " {temperatureC}°C";
          format = " {temperatureC}°C";

        };

        mpris = {
          format = "{player_icon} {title} <small>[{position}/{length}]</small>";
          format-paused = "{player_icon}  <i>{title} <small>[{position}/{length}]</small></i>";
          player-icons = {
            "default" = "▶ ";
            "mpv" = "🎵 ";
            "spotify" = " ";
          };
          status-icons = {
            "paused" = " ";
          };
          interval = 1;
          title-len = 20;
          artist-len = 20;
          album-len = 10;
        };
        "custom/left-arrow-dark" = {
          format = "";
          tooltip = false;
        };
        "custom/outer-left-arrow-dark" = {
          format = "";
          tooltip = false;
        };
        "custom/left-arrow-light" = {
          format = "";
          tooltip = false;
        };
        "custom/right-arrow-dark" = {
          format = "";
          tooltip = false;
        };
        "custom/outer-right-arrow-dark" = {
          format = "";
          tooltip = false;
        };
        "custom/right-arrow-light" = {
          format = "";
          tooltip = false;
        };
        "sway/workspaces" = {
          disable-scroll = true;
          format = "{name}";
        };

        "clock#1" = {
          min-length = 8;
          interval = 1;
          format = "{:%H:%M:%S}";
          # on-click-right= "gnome-clocks";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "clock#2" = {
          format = "{:%d. %B %Y}";
          # on-click-right= "gnome-clocks";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        pulseaudio = {
          format = "{icon} {volume:2}%";
          format-bluetooth = "{icon} {volume}%";
          format-muted = "MUTE";
          format-icons = {
            headphones = "";
            default = [
              ""
              ""
            ];
          };
          scroll-step = 1;
          on-click = "pamixer -t";
          on-click-right = "pavucontrol";
        };

        memory = {
          interval = 5;
          format = " {}%";
          tooltip-format = "Memory: {used:0.1f}G/{total:0.1f}G\nSwap: {swapUsed}G/{swapTotal}G";
        };
        cpu = {
          format = config.swarselsystems.cpuString;
          min-length = 6;
          interval = 5;
          format-icons = [ "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
          # on-click-right= "com.github.stsdc.monitor";
          on-click-right = "kitty -o confirm_os_window_close=0 btm";

        };
        "custom/vpn" = {
          format = "()";
          exec = "echo '{\"class\": \"connected\"}'";
          exec-if = "test -d /proc/sys/net/ipv4/conf/tun0";
          return-type = "json";
          interval = 5;
        };
        battery = {
          states = {
            "warning" = 60;
            "error" = 30;
            "critical" = 15;
          };
          interval = 5;
          format = "{icon} {capacity}%";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
          on-click-right = "wlogout -p layer-shell";
        };
        disk = {
          interval = 30;
          format = "Disk {percentage_used:2}%";
          path = "/";
          states = {
            "warning" = 80;
            "critical" = 90;
          };
          tooltip-format = "{used} used out of {total} on {path} ({percentage_used}%)\n{free} free on {path} ({percentage_free}%)";
        };
        tray = {
          icon-size = 20;
        };
        network = {
          interval = 5;
          format-wifi = "{signalStrength}% ";
          format-ethernet = "";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
          tooltip-format-ethernet = "{ifname} via {gwaddr}: {essid} {ipaddr}/{cidr}\n\n⇡{bandwidthUpBytes} ⇣{bandwidthDownBytes}";
          tooltip-format-wifi = "{ifname} via {gwaddr}: {essid} {ipaddr}/{cidr} \n{signaldBm}dBm @ {frequency}MHz\n\n⇡{bandwidthUpBytes} ⇣{bandwidthDownBytes}";
        };
      };
    };
    style = builtins.readFile ../../../programs/waybar/style.css;
  };
}
