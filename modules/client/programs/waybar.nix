{
  flake.modules.homeManager.waybar =
    {
      self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      generateIcons =
        n: lib.concatStringsSep " " (builtins.map (x: "{icon" + toString x + "}") (lib.range 0 (n - 1)));
      modulesLeft = [
        "custom/outer-left-arrow-dark"
        "mpris"
        "custom/left-arrow-light"
        "network"
        "custom/vpn"
        "custom/left-arrow-dark"
        "pulseaudio"
        "custom/left-arrow-light"
      ];
      modulesRight = [
        "custom/left-arrow-dark"
        "group/hardware"
        "custom/left-arrow-light"
        "clock#2"
        "custom/left-arrow-dark"
        "clock#1"
      ];
    in
    {
      options.swarselsystems = {
        cpuCount = lib.mkOption {
          default = 8;
          type = lib.types.int;
        };
        cpuString = lib.mkOption {
          default = generateIcons config.swarselsystems.cpuCount;
          description = "The generated icons string for use by Waybar.";
          internal = true;
          type = lib.types.str;
        };
        temperatureHwmon = {
          input-filename = lib.mkOption {
            default = "";
            type = lib.types.str;
          };
          isAbsolutePath = lib.mkEnableOption "absolute temperature path";
          path = lib.mkOption {
            default = "";
            type = lib.types.str;
          };
        };
        waybarModules = lib.mkOption {
          default =
            modulesLeft
            ++ [
              "custom/pseudobat"
            ]
            ++ modulesRight;
          type = lib.types.listOf lib.types.str;
        };
      };
      config = {
        swarselsystems = {
          enabledHomeModules = [ "waybar" ];
          homeSopsSecrets.github-notifications-token = { };
          waybarModules = lib.mkIf config.swarselsystems.isLaptop (
            modulesLeft
            ++ [
              "battery"
            ]
            ++ modulesRight
          );
        };
        services.playerctld.enable = true;
        programs.waybar = {
          enable = true;
          settings.mainBar = {
            "backlight/slider" = {
              device = "intel_backlight";
              max = 100;
              min = 0;
              orientation = "horizontal";
            };
            battery = {
              format = "{icon} {capacity}%";
              format-charging = "{capacity}% ";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];
              format-plugged = "{capacity}% ";
              interval = 5;
              on-click-right = "wlogout -p layer-shell";
              states = {
                "critical" = 15;
                "error" = 30;
                "warning" = 60;
              };
            };
            "clock#1" = {
              format = "{:%H:%M:%S}";
              interval = 1;
              min-length = 8;
              tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            };
            "clock#2" = {
              format = "{:%d. %B %Y}";
              tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            };
            cpu = {
              format = config.swarselsystems.cpuString;
              format-icons = [
                "▁"
                "▂"
                "▃"
                "▄"
                "▅"
                "▆"
                "▇"
                "█"
              ];
              interval = 5;
              min-length = 6;
              on-click-right = "${pkgs.kitty}/bin/kitty -o confirm_os_window_close=0 btm";

            };
            "custom/configwarn" = {
              exec = "${pkgs.waybarupdate}/bin/waybarupdate";
              interval = 60;
            };
            "custom/github" = {
              exec = "${pkgs.github-notifications}/bin/github-notifications";
              format = "{}  ";
              interval = 60;
              on-click = "${pkgs.xdg-utils}/bin/xdg-open https://github.com/notifications";
              return-type = "json";
            };
            "custom/left-arrow-dark" = {
              format = "";
              tooltip = false;
            };
            "custom/left-arrow-light" = {
              format = "";
              tooltip = false;
            };
            "custom/outer-left-arrow-dark" = {
              format = "";
              tooltip = false;
            };
            "custom/outer-right-arrow-dark" = {
              format = "";
              tooltip = false;
            };
            "custom/pseudobat" = lib.mkIf (!config.swarselsystems.isLaptop) {
              format = "";
              on-click-right = "${pkgs.wlogout}/bin/wlogout -p layer-shell";
            };
            "custom/right-arrow-dark" = {
              format = "";
              tooltip = false;
            };
            "custom/right-arrow-light" = {
              format = "";
              tooltip = false;
            };
            "custom/scratchpad-indicator" = {
              exec = "${pkgs.swayfx}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq 'recurse(.nodes[]) | first(select(.name==\"__i3_scratch\")) | .floating_nodes | length | select(. >= 1)'";
              format = "{} ";
              interval = 3;
              on-click = "${pkgs.swayfx}/bin/swaymsg 'scratchpad show'";
              on-click-right = "${pkgs.swayfx}/bin/swaymsg 'move scratchpad'";
            };
            "custom/vpn" = {
              exec = "echo '{\"class\": \"connected\"}'";
              exec-if = "${pkgs.toybox}/bin/test -d /proc/sys/net/ipv4/conf/tun0";
              format = "()";
              interval = 5;
              return-type = "json";
            };
            disk = {
              format = "Disk {percentage_used:2}%";
              interval = 30;
              path = "/";
              states = {
                "critical" = 90;
                "warning" = 80;
              };
              tooltip-format = "{used} used out of {total} on {path} ({percentage_used}%)\n{free} free on {path} ({percentage_free}%)";
            };
            "group/hardware" = {
              drawer."transition-left-to-right" = false;
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
              orientation = "inherit";
            };
            id = "bar-0";
            idle_inhibitor = {
              format = "{icon}";
              format-icons = {
                activated = "";
                deactivated = "";
              };
            };
            ipc = true;
            layer = "top";
            memory = {
              format = " {}%";
              interval = 5;
              tooltip-format = "Memory: {used:0.1f}G/{total:0.1f}G\nSwap: {swapUsed}G/{swapTotal}G";
            };
            modules-center = [
              "sway/mode"
              "privacy"
              "custom/github"
              "custom/configwarn"
              "custom/nix-updates"
            ];
            modules-left = [
              "sway/workspaces"
              "niri/workspaces"
              "custom/outer-right-arrow-dark"
              "niri/window"
              "sway/window"
            ];
            modules-right = config.swarselsystems.waybarModules;
            mpris = {
              album-len = 10;
              artist-len = 20;
              format = "{player_icon} {title} <small>[{position}/{length}]</small>";
              format-paused = "{player_icon}  <i>{title} <small>[{position}/{length}]</small></i>";
              interval = 1;
              player-icons = {
                "default" = "▶ ";
                "mpv" = "🎵 ";
                "spotify" = " ";
              };
              status-icons."paused" = " ";
              title-len = 20;
            };
            network = {
              format-alt = "{ifname}: {ipaddr}/{cidr}";
              format-disconnected = "Disconnected ⚠";
              format-ethernet = "";
              format-linked = "{ifname} (No IP) ";
              format-wifi = "{signalStrength}% ";
              interval = 5;
              tooltip-format-ethernet = "{ifname} via {gwaddr}: {essid} {ipaddr}/{cidr}\n\n⇡{bandwidthUpBytes} ⇣{bandwidthDownBytes}";
              tooltip-format-wifi = "{ifname} via {gwaddr}: {essid} {ipaddr}/{cidr} \n{signaldBm}dBm @ {frequency}MHz\n\n⇡{bandwidthUpBytes} ⇣{bandwidthDownBytes}";
            };
            "niri/window".format = "<span style=\"italic\" font-weight=\"bold\">{title} ({app_id})</span>";
            position = "top";
            power-profiles-daemon = {
              format = "{icon}";
              format-icons = {
                "balanced" = "";
                "default" = "";
                "performance" = "";
                "power-saver" = "";
              };
              tooltip = true;
              tooltip-format = "Power profile: {profile}\nDriver: {driver}";
            };
            pulseaudio = {
              format = "{icon} {volume:2}%";
              format-bluetooth = "{icon} {volume}%";
              format-icons = {
                default = [
                  ""
                  ""
                ];
                headphones = "";
              };
              format-muted = "MUTE";
              on-click = "${pkgs.pamixer}/bin/pamixer -t";
              on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
              scroll-step = 1;
            };
            "sway/mode".format = "<span style=\"italic\" font-weight=\"bold\">{}</span>";
            "sway/workspaces" = {
              disable-scroll = true;
              format = "{name}";
            };
            temperature = {
              critical-threshold = 80;
              format = " {temperatureC}°C";
              format-critical = " {temperatureC}°C";
              hwmon-path = lib.mkIf (
                !config.swarselsystems.temperatureHwmon.isAbsolutePath
              ) config.swarselsystems.temperatureHwmon.path;
              hwmon-path-abs = lib.mkIf config.swarselsystems.temperatureHwmon.isAbsolutePath config.swarselsystems.temperatureHwmon.path;
              input-filename = lib.mkIf config.swarselsystems.temperatureHwmon.isAbsolutePath config.swarselsystems.temperatureHwmon.input-filename;

            };
            tray.icon-size = 20;
          };
          style = builtins.readFile (self + /files/waybar/style.css);
          systemd = {
            enable = false;
            targets = [
              "sway-session.target"
            ];
          };
        };
      };
    };
}
