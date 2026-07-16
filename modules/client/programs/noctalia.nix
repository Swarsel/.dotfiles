{ config, ... }:
let
  fmods = config.flake.modules;
in
{
  flake-file.inputs = {
    noctalia = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:noctalia-dev/noctalia-shell";
    };

    noctoggle = {
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
      url = "github:Swarsel/noctoggle";
    };
  };

  flake.modules = {
    homeManager.noctalia =
      {
        self,
        inputs,
        config,
        lib,
        pkgs,
        confLib,
        ...
      }:
      let
        inherit (confLib.getConfig.repo.secrets.common) caldavTasksEndpoint;
        brightnessctl = lib.getExe pkgs.brightnessctl;
      in
      {
        imports = [
          inputs.noctalia.homeModules.default
        ];
        options = {
          swarselsystems.noctalia-systemd = lib.swarselsystems.mkTrueOption;
        };
        config = {
          swarselsystems.enabledHomeModules = [ "optional-noctalia" ];
          programs = {
            fastfetch.enable = true;
            noctalia = {
              enable = true;
              package = pkgs.noctalia;
              settings = {
                audio = {
                  enable_overdrive = false;
                  enable_sounds = false;
                };
                bar.main = {
                  auto_hide = false;
                  background_opacity = 0.5;
                  border_width = 0.0;
                  capsule = false;
                  center = [
                    "active_window"
                    "recorder_2"
                  ];
                  color = "on_surface";
                  end = [
                    "tray"
                    "volume"
                    "network"
                    "bluetooth"
                    "battery"
                    "spacer_1"
                    "clock"
                    "control-center"
                  ];
                  font_weight = 500;
                  margin_edge = 0;
                  margin_ends = 0;
                  position = "top";
                  radius = 12;
                  reserve_space = false;
                  scale = 1.1;
                  start = [ "workspaces" ];
                  thickness = 40;
                  widget_spacing = 10;
                };
                battery = {
                  device."/org/freedesktop/UPower/devices/battery_hidpp_battery_3".warning_threshold = 15;
                  warning_threshold = 20;
                };
                brightness.enable_ddcutil = false;
                calendar = {
                  account.caldav = {
                    name = "CalDAV";
                    provider = "custom";
                    server_url = caldavTasksEndpoint;
                    type = "caldav";
                    username = config.swarselsystems.mainUser;
                  };
                  enabled = true;
                };
                control_center = {
                  shortcuts = [
                    { type = "wifi"; }
                    { type = "bluetooth"; }
                    { type = "notification"; }
                    { type = "caffeine"; }
                    { type = "clipboard"; }
                    { type = "power_profile"; }
                  ];
                  sidebar = "compact";
                  sidebar_section = "compact";
                };
                desktop_widgets.enabled = false;
                dock = {
                  background_opacity = 1.0;
                  enabled = false;
                };
                idle = {
                  behavior = {
                    dim = {
                      action = "command";
                      command = "${brightnessctl} -s; ${brightnessctl} set 80%-";
                      enabled = true;
                      resume_command = "${brightnessctl} -r";
                      timeout = 60;
                    };
                    lock = {
                      action = "lock";
                      enabled = true;
                      timeout = 300;
                    };
                    suspend = {
                      action = "lock_and_suspend";
                      enabled = true;
                      timeout = 600;
                    };
                  };
                  behavior_order = [
                    "dim"
                    "lock"
                    "suspend"
                  ];
                  pre_action_fade_seconds = 0.0;
                };
                location = {
                  address = confLib.getConfig.repo.secrets.common.location.timezoneSpecific;
                  auto_locate = false;
                };
                lockscreen = {
                  blurred_desktop = true;
                  monitors = [ "eDP-2" ];
                };
                lockscreen_widgets = {
                  enabled = true;
                  grid = {
                    cell_size = 64;
                    major_interval = 4;
                    visible = true;
                  };
                  schema_version = 2;
                  widget = {
                    "lockscreen-login-box@eDP-2" = {
                      box_height = 0.0;
                      box_width = 0.0;
                      cx = 853.5;
                      cy = 981.5;
                      enabled = true;
                      output = "eDP-2";
                      rotation = 0.0;
                      type = "login_box";
                    };
                    lockscreen-widget-0000000000000001 = {
                      box_height = 192.0;
                      box_width = 192.0;
                      cx = 853.5;
                      cy = 789.5;
                      enabled = true;
                      output = "eDP-2";
                      rotation = 0.0;
                      settings.background = false;
                      type = "fancy_audio_visualizer";
                    };
                    lockscreen-widget-0000000000000002 = {
                      box_height = 0.0;
                      box_width = 0.0;
                      cx = 853.5;
                      cy = 533.5;
                      enabled = true;
                      output = "eDP-2";
                      rotation = 0.0;
                      settings = {
                        background = false;
                        image_path = "${self}/files/icons/swarsel.png";
                        opacity = 1.0;
                      };
                      type = "sticker";
                    };
                  };
                  widget_order = [
                    "lockscreen-login-box@DP-9"
                    "lockscreen-login-box@DP-8"
                    "lockscreen-login-box@eDP-2"
                    "lockscreen-widget-0000000000000001"
                    "lockscreen-widget-0000000000000002"
                  ];
                };
                nightlight = {
                  enabled = true;
                  force = false;
                  temperature_day = 5500;
                  temperature_night = 3700;
                };
                notification = {
                  background_opacity = 0.5;
                  enable_daemon = true;
                  layer = "overlay";
                  position = "top_right";
                };
                osd = {
                  background_opacity = 0.5;
                  orientation = "vertical";
                  position = "center_right";
                  position_vertical = "center_right";

                };
                plugin_settings."noctalia/screen_recorder" = {
                  audio_codec = "opus";
                  audio_source = "default_output";
                  color_range = "limited";
                  copy_to_clipboard = true;
                  filename_pattern = "recording_%Y%m%d_%H%M%S";
                  frame_rate = 60;
                  hide_inactive = true;
                  quality = "very_high";
                  resolution = "original";
                  show_cursor = true;
                  video_codec = "h264";
                  video_source = "portal";
                };
                plugins.enabled = [
                  "noctalia/screen_recorder"
                  "noctalia/kaomoji"
                  "whyoolw/sharednd"
                ];
                shell = {
                  animation = {
                    enabled = true;
                    speed = 4.0;
                  };
                  avatar_path = "${self}/files/icons/swarsel.png";
                  clipboard_auto_paste = "off";
                  clipboard_enabled = true;
                  external_ip_enabled = true;
                  launch_apps_as_systemd_services = true;
                  panel = {
                    control_center_placement = "attached";
                    launcher_categories = false;
                    launcher_compact = true;
                    launcher_placement = "centered";
                    launcher_show_icons = true;
                    open_near_click_control_center = true;
                    session_placement = "centered";
                    transparency_mode = "solid";
                  };
                  screen_corners.enabled = false;
                  session.actions = [
                    {
                      action = "lock";
                      shortcut = "l";
                    }
                    {
                      action = "suspend";
                      shortcut = "s";
                    }
                    {
                      action = "command";
                      command = "systemctl hibernate";
                      glyph = "suspend";
                      label = "Hibernate";
                      shortcut = "h";
                    }
                    {
                      action = "reboot";
                      shortcut = "r";
                    }
                    {
                      action = "logout";
                      shortcut = "u";
                    }
                    {
                      action = "shutdown";
                      shortcut = "p";
                    }
                    {
                      action = "command";
                      command = "systemctl reboot --firmware-setup";
                      glyph = "reboot";
                      label = "Reboot to UEFI";
                      shortcut = "b";
                    }
                  ];
                  settings_show_advanced = true;
                  shadow.direction = "center";
                  telemetry_enabled = false;
                  time_format = "{:%H:%M}";
                };
                system.monitor = {
                  cpu_poll_seconds = 1.0;
                  cpu_temp_activity_threshold = 80.0;
                  cpu_temp_critical_threshold = 90.0;
                  cpu_usage_activity_threshold = 80.0;
                  cpu_usage_critical_threshold = 90.0;
                  disk_pct_activity_threshold = 80.0;
                  disk_pct_critical_threshold = 90.0;
                  disk_poll_seconds = 30.0;
                  enabled = true;
                  gpu_poll_seconds = 3.0;
                  gpu_temp_activity_threshold = 80.0;
                  gpu_temp_critical_threshold = 90.0;
                  gpu_usage_activity_threshold = 80.0;
                  gpu_usage_critical_threshold = 90.0;
                  memory_poll_seconds = 1.0;
                  network_poll_seconds = 1.0;
                  ram_pct_activity_threshold = 80.0;
                  ram_pct_critical_threshold = 90.0;
                  swap_pct_activity_threshold = 80.0;
                  swap_pct_critical_threshold = 90.0;
                };
                theme = {
                  custom_palette = "stylix";
                  mode = "dark";
                  source = "custom";
                  templates = {
                    enable_builtin_templates = false;
                    enable_community_templates = false;
                  };
                };
                wallpaper = {
                  automation = {
                    enabled = true;
                    interval_seconds = 300;
                    order = "random";
                    recursive = true;
                  };
                  directory = "${self}/files/wallpaper/landscape";
                  edge_smoothness = 0.05;
                  enabled = true;
                  fill_mode = "crop";
                  transition = [
                    "fade"
                    "wipe"
                    "disc"
                    "stripes"
                    "zoom"
                    "honeycomb"
                  ];
                  transition_duration = 500.0;
                };
                weather = {
                  effects = false;
                  enabled = true;
                  unit = "celsius";
                };
                widget = {
                  active_window = {
                    display = "icon_and_text";
                    max_length = 300;
                    title_scroll = "hover";
                  };
                  battery = {
                    device = "auto";
                    display_mode = "graphic";
                    hide_when_full = true;
                    show_label = true;
                  };
                  bluetooth = {
                    hide_when_no_connected_device = true;
                    show_label = true;
                  };
                  clock = {
                    format = "{:%a %d. %b %H:%M:%S}";
                    tooltip_format = "{:%a %d. %b %H:%M:%S}";
                  };
                  "control-center" = {
                    custom_image = "${self}/files/icons/swarsel.png";
                    custom_image_colorize = true;
                    glyph = "noctalia";
                  };
                  network.show_label = false;
                  notifications.hide_when_no_unread = false;
                  spacer_1.type = "spacer";
                  tray = {
                    drawer = true;
                    hidden = [ "bluetooth" ];
                  };
                  volume = {
                    device = "output";
                    scroll_step = 5;
                    show_label = true;
                  };
                  workspaces = {
                    display = "name";
                    empty_color = "primary";
                    focused_color = "primary";
                    hide_when_empty = true;
                    labels_only_when_occupied = false;
                    max_label_chars = 4;
                    occupied_color = "primary";
                  };
                };
              };
              systemd.enable = config.swarselsystems.noctalia-systemd;
            };
          };
          systemd.user = lib.mkMerge [
            { sessionVariables.TERMINAL = "kitty"; }
            (lib.mkIf config.swarselsystems.noctalia-systemd {
              services = {
                noctalia = {
                  Install.WantedBy = [ "noctalia-shell.target" ];
                  Unit.PartOf = [ "noctalia-shell.target" ];
                };
                noctalia-init = {

                  Install = {
                    WantedBy = [ "tray.target" ];
                  };
                  Service = {
                    ExecStart = "${pkgs.coreutils}/bin/sleep 3";
                    RemainAfterExit = true;
                    Type = "oneshot";
                  };
                  Unit = {
                    After = [ "noctalia.service" ];
                    Requires = [ "noctalia.service" ];
                  };
                };
              };
              targets = {
                noctalia-shell.Unit = {
                  After = [ "graphical-session.target" ];
                };
                tray = {
                  Install.WantedBy = [ "noctalia-shell.target" ];
                  Unit = {
                    After = [
                      "noctalia.service"
                      "noctalia-init.service"
                    ];
                    Wants = [ "noctalia-init.service" ];
                  };
                };
              };
            })
          ];
        };
      };
    nixos.noctalia = { inputs, lib, ... }: {
      imports = lib.optionals (inputs ? noctoggle) [
        inputs.noctoggle.nixosModules.default
        (
          {
            inputs,
            config,
            pkgs,
            ...
          }:
          {
            imports = [
              "${inputs.nixpkgs-dev}/nixos/modules/programs/gpu-screen-recorder.nix"
            ];
            services = {
              gnome.evolution-data-server = {
                enable = false; # needed for calendar integration
              };
              noctoggle = {
                enable = true;
                hideCommand = "${lib.getExe pkgs.noctalia} msg bar-hide";
                noctaliaPackage = pkgs.noctalia;
                showCommand = "${lib.getExe pkgs.noctalia} msg bar-show";
              };
              upower.enable = true; # needed for battery percentage

            };
            programs = {
              evolution.enable = false;
              gpu-screen-recorder.enable = true;
            };
            disabledModules = [ "programs/gpu-screen-recorder.nix" ];
            home-manager.users.${config.swarselsystems.mainUser}.imports = [
              fmods.homeManager.noctalia
            ];
            systemd.services.lock-before-sleep = {
              before = [ "sleep.target" ];
              serviceConfig = {
                ExecStart = "${pkgs.systemd}/bin/loginctl lock-sessions";
                Type = "oneshot";
              };
              wantedBy = [ "sleep.target" ];
            };
          }
        )
      ];
    };
  };
}
