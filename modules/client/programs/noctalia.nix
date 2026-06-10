{ config, ... }:
let
  fmods = config.flake.modules;
in
{
  flake-file.inputs = {
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctoggle.url = "github:Swarsel/noctoggle";
  };

  flake.modules = {
    nixos.noctalia = { inputs, lib, ... }: {
      imports = lib.optionals (inputs ? noctoggle) [
        inputs.noctoggle.nixosModules.default
        ({ inputs, config, pkgs, ... }: {
          disabledModules = [ "programs/gpu-screen-recorder.nix" ];
          imports = [
            "${inputs.nixpkgs-dev}/nixos/modules/programs/gpu-screen-recorder.nix"
          ];
          home-manager.users.${config.swarselsystems.mainUser}.imports = [
            fmods.homeManager.noctalia
          ];
          services = {
            upower.enable = true; # needed for battery percentage
            gnome.evolution-data-server = {
              enable = false; # needed for calendar integration
            };

            noctoggle = {
              enable = true;
              noctaliaPackage = pkgs.noctalia;
              showCommand = "${lib.getExe pkgs.noctalia} msg bar-show";
              hideCommand = "${lib.getExe pkgs.noctalia} msg bar-hide";
            };

          };
          programs = {
            gpu-screen-recorder.enable = true;
            evolution.enable = false;
          };
        })
      ];
    };

    homeManager.noctalia = { self, inputs, config, pkgs, lib, confLib, ... }:
      let
        inherit (confLib.getConfig.repo.secrets.common) caldavTasksEndpoint;
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

          systemd.user = lib.mkMerge [
            { sessionVariables.TERMINAL = "kitty"; }
            (lib.mkIf config.swarselsystems.noctalia-systemd {
              targets = {
                noctalia-shell.Unit = {
                  After = [ "graphical-session.target" ];
                };
                tray = {
                  Unit = {
                    Wants = [ "noctalia-init.service" ];
                    After = [
                      "noctalia.service"
                      "noctalia-init.service"
                    ];
                  };
                  Install.WantedBy = [ "noctalia-shell.target" ];
                };
              };
              services = {
                noctalia = {
                  Unit.PartOf = [ "noctalia-shell.target" ];
                  Install.WantedBy = [ "noctalia-shell.target" ];
                };
                noctalia-init = {

                  Unit = {
                    Requires = [ "noctalia.service" ];
                    After = [ "noctalia.service" ];
                  };

                  Service = {
                    Type = "oneshot";
                    ExecStart = "${pkgs.coreutils}/bin/sleep 3";
                    RemainAfterExit = true;
                  };

                  Install = {
                    WantedBy = [ "tray.target" ];
                  };
                };
              };
            })
          ];

          programs = {
            fastfetch.enable = true;
            noctalia = {
              enable = true;
              package = pkgs.noctalia;
              systemd.enable = config.swarselsystems.noctalia-systemd;
              settings = {
                shell = {
                  font_family = "FiraCode Nerd Font Mono";
                  time_format = "{:%H:%M}";
                  telemetry_enabled = false;
                  clipboard_enabled = true;
                  clipboard_auto_paste = "off";
                  avatar_path = "${self}/files/icons/swarsel.png";
                  settings_show_advanced = true;
                  animation = {
                    enabled = true;
                    speed = 4.0;
                  };
                  shadow.direction = "center";
                  screen_corners.enabled = false;
                  panel = {
                    transparency_mode = "solid";
                    launcher_placement = "centered";
                    session_placement = "centered";
                    control_center_placement = "attached";
                    open_near_click_control_center = true;
                    launcher_categories = false;
                    launcher_compact = true;
                    launcher_show_icons = true;
                  };
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
                      label = "Hibernate";
                      glyph = "suspend";
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
                      label = "Reboot to UEFI";
                      glyph = "reboot";
                      shortcut = "b";
                    }
                  ];
                };

                bar.main = {
                  position = "top";
                  background_opacity = 0.5;
                  radius = 12;
                  border_width = 0.0;
                  margin_ends = 0;
                  margin_edge = 0;
                  reserve_space = false;
                  auto_hide = false;
                  capsule = false;
                  start = [ "workspaces" ];
                  center = [ "active_window" "noctalia/screen_recorder:recorder" ];
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
                };

                widget = {
                  workspaces = {
                    display = "name";
                    max_label_chars = 4;
                    labels_only_when_occupied = false;
                    hide_when_empty = true;
                    focused_color = "primary";
                    occupied_color = "primary";
                    empty_color = "primary";
                  };
                  active_window = {
                    max_length = 300;
                    title_scroll = "hover";
                    display = "icon_and_text";
                  };
                  tray = {
                    hidden = [ "bluetooth" ];
                    drawer = true;
                  };
                  volume = {
                    show_label = true;
                    scroll_step = 5;
                    device = "output";
                  };
                  notifications.hide_when_no_unread = false;
                  network.show_label = true;
                  bluetooth = {
                    show_label = true;
                    hide_when_no_connected_device = true;
                  };
                  battery = {
                    device = "auto";
                    display_mode = "graphic";
                    show_label = true;
                    hide_when_full = true;
                  };
                  clock = {
                    format = "{:%a %d. %b %H:%M:%S}";
                    tooltip_format = "{:%a %d. %b %H:%M:%S}";
                  };
                  "control-center" = {
                    glyph = "noctalia";
                    custom_image = "${self}/files/icons/swarsel.png";
                    custom_image_colorize = true;
                  };
                  spacer_1.type = "spacer";
                };

                location = {
                  auto_locate = false;
                  address = confLib.getConfig.repo.secrets.common.location.timezoneSpecific;
                };

                weather = {
                  enabled = true;
                  unit = "celsius";
                  effects = false;
                };

                calendar = {
                  enabled = true;
                  account.caldav = {
                    type = "caldav";
                    provider = "custom";
                    name = "CalDAV";
                    server_url = caldavTasksEndpoint;
                    username = config.swarselsystems.mainUser;
                  };
                };

                nightlight = {
                  enabled = true;
                  force = false;
                  temperature_day = 5500;
                  temperature_night = 3700;
                };

                theme = {
                  source = "builtin";
                  builtin = "Nord";
                  community_palette = "Oxocarbon";
                  mode = "dark";
                  wallpaper_scheme = "m3-content";
                };

                lockscreen.monitors = [ "eDP-2" ];

                lockscreen_widgets = {
                  enabled = true;
                  schema_version = 2;
                  widget_order = [
                    "lockscreen-login-box@DP-9"
                    "lockscreen-login-box@DP-8"
                    "lockscreen-login-box@eDP-2"
                    "lockscreen-widget-0000000000000001"
                    "lockscreen-widget-0000000000000002"
                  ];
                  grid = {
                    cell_size = 64;
                    major_interval = 4;
                    visible = true;
                  };
                  widget = {
                    "lockscreen-login-box@eDP-2" = {
                      type = "login_box";
                      output = "eDP-2";
                      cx = 853.5;
                      cy = 981.5;
                      enabled = true;
                    };
                    lockscreen-widget-0000000000000001 = {
                      type = "fancy_audio_visualizer";
                      output = "eDP-2";
                      cx = 853.5;
                      cy = 789.5;
                      box_width = 192.0;
                      box_height = 192.0;
                      enabled = true;
                      settings.background = false;
                    };
                    lockscreen-widget-0000000000000002 = {
                      type = "sticker";
                      output = "eDP-2";
                      cx = 853.5;
                      cy = 533.5;
                      enabled = true;
                      settings = {
                        background = false;
                        image_path = "${self}/files/icons/swarsel.png";
                        opacity = 1.0;
                      };
                    };
                  };
                };

                wallpaper = {
                  enabled = true;
                  directory = "${self}/files/wallpaper/landscape";
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
                  edge_smoothness = 0.05;
                  automation = {
                    enabled = true;
                    interval_seconds = 300;
                    order = "random";
                    recursive = true;
                  };
                };

                notification = {
                  enable_daemon = true;
                  position = "top_right";
                  layer = "overlay";
                  background_opacity = 0.5;
                };

                osd = {
                  position = "center_right";
                  orientation = "vertical";
                  background_opacity = 0.5;
                };

                audio = {
                  enable_overdrive = false;
                  enable_sounds = false;
                };

                brightness.enable_ddcutil = false;

                battery = {
                  warning_threshold = 20;
                  device."/org/freedesktop/UPower/devices/battery_hidpp_battery_3".warning_threshold = 15;
                };

                system.monitor = {
                  enabled = true;
                  cpu_poll_seconds = 1.0;
                  gpu_poll_seconds = 3.0;
                  memory_poll_seconds = 1.0;
                  network_poll_seconds = 1.0;
                  disk_poll_seconds = 30.0;
                  cpu_usage_activity_threshold = 80.0;
                  cpu_usage_critical_threshold = 90.0;
                  cpu_temp_activity_threshold = 80.0;
                  cpu_temp_critical_threshold = 90.0;
                  gpu_temp_activity_threshold = 80.0;
                  gpu_temp_critical_threshold = 90.0;
                  gpu_usage_activity_threshold = 80.0;
                  gpu_usage_critical_threshold = 90.0;
                  ram_pct_activity_threshold = 80.0;
                  ram_pct_critical_threshold = 90.0;
                  swap_pct_activity_threshold = 80.0;
                  swap_pct_critical_threshold = 90.0;
                  disk_pct_activity_threshold = 80.0;
                  disk_pct_critical_threshold = 90.0;
                };

                dock.enabled = false;

                desktop_widgets.enabled = false;

                control_center = {
                  sidebar = "compact";
                  sidebar_section = "compact";
                  shortcuts = [
                    { type = "wifi"; }
                    { type = "bluetooth"; }
                    { type = "notification"; }
                    { type = "caffeine"; }
                    { type = "clipboard"; }
                    { type = "power_profile"; }
                  ];
                };

                plugins.enabled = [ "noctalia/screen_recorder" ];

                plugin_settings."noctalia/screen_recorder" = {
                  video_source = "portal";
                  filename_pattern = "recording_%Y%m%d_%H%M%S";
                  frame_rate = 60;
                  video_codec = "h264";
                  quality = "very_high";
                  resolution = "original";
                  audio_source = "default_output";
                  audio_codec = "opus";
                  show_cursor = true;
                  color_range = "limited";
                  copy_to_clipboard = true;
                  hide_inactive = true;
                };
              };
            };
          };
        };
      };
  };
}
