{ self, config, lib, pkgs, ... }:
let
  inherit (config.swarselsystems) xdgDir;
  generateIcons = n: lib.concatStringsSep " " (builtins.map (x: "{icon" + toString x + "}") (lib.range 0 (n - 1)));
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
  options.swarselmodules.waybar = lib.mkEnableOption "waybar settings";
  options.swarselsystems = {
    cpuCount = lib.mkOption {
      type = lib.types.int;
      default = 8;
    };
    temperatureHwmon = {
      isAbsolutePath = lib.mkEnableOption "absolute temperature path";
      path = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      input-filename = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
    };
    waybarModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = modulesLeft ++ [
        "custom/pseudobat"
      ] ++ modulesRight;
    };
    cpuString = lib.mkOption {
      type = lib.types.str;
      default = generateIcons config.swarselsystems.cpuCount;
      description = "The generated icons string for use by Waybar.";
      internal = true;
    };
  };
  config = lib.mkIf config.swarselmodules.waybar {

    swarselsystems = {
      waybarModules = lib.mkIf config.swarselsystems.isLaptop (modulesLeft ++ [
        "battery"
      ] ++ modulesRight);
    };

    sops.secrets = lib.mkIf (!config.swarselsystems.isPublic && !config.swarselsystems.isNixos) {
      github-notifications-token = { path = "${xdgDir}/secrets/github-notifications-token"; };
    };

    services.playerctld.enable = true;

    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        target = "sway-session.target";
      };
      settings = {
        mainBar = {
          ipc = true;
          id = "bar-0";
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
            on-click-right = "${pkgs.wlogout}/bin/wlogout -p layer-shell";
          };

          "custom/configwarn" = {
            exec = "${pkgs.waybarupdate}/bin/waybarupdate";
            interval = 60;
          };

          "custom/scratchpad-indicator" = {
            interval = 3;
            exec = "${pkgs.swayfx}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq 'recurse(.nodes[]) | first(select(.name==\"__i3_scratch\")) | .floating_nodes | length | select(. >= 1)'";
            format = "{} ";
            on-click = "${pkgs.swayfx}/bin/swaymsg 'scratchpad show'";
            on-click-right = "${pkgs.swayfx}/bin/swaymsg 'move scratchpad'";
          };

          "custom/github" = {
            format = "{}  ";
            return-type = "json";
            interval = 60;
            exec = "${pkgs.github-notifications}/bin/github-notifications";
            on-click = "${pkgs.xdg-utils}/bin/xdg-open https://github.com/notifications";
          };

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
            on-click = "${pkgs.pamixer}/bin/pamixer -t";
            on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
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
            on-click-right = "${pkgs.kitty}/bin/kitty -o confirm_os_window_close=0 btm";

          };
          "custom/vpn" = {
            format = "()";
            exec = "echo '{\"class\": \"connected\"}'";
            exec-if = "${pkgs.toybox}/bin/test -d /proc/sys/net/ipv4/conf/tun0";
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
      style = builtins.readFile (self + /files/waybar/style.css);
    };
  };
}
