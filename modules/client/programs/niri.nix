{ config, ... }:
let
  fmods = config.flake.modules;
in
{
  flake-file.inputs = {
    niri-flake = {
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
      url = "github:sodiboo/niri-flake";
    };

    niritiling = {
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
      url = "github:Swarsel/niritiling";
    };
  };

  flake.modules = {
    homeManager.niri =
      {
        inputs,
        config,
        lib,
        pkgs,
        type,
        vars,
        ...
      }:
      {
        imports = [
          fmods.homeManager.gnome-keyring
        ]
        ++ lib.optionals (type != "nixos") [
          inputs.niri-flake.homeModules.niri
        ];
        config = {
          swarselsystems.enabledHomeModules = [ "optional-niri" ];
          programs.niri = {
            package = pkgs.niri-stable; # which package to use for niri validation
            settings = {
              binds =
                with config.lib.niri.actions;
                let
                  sh = spawn "sh" "-c";
                in
                {
                  "Mod+0".action = focus-workspace 0;
                  "Mod+1".action = focus-workspace 1;
                  "Mod+2".action = focus-workspace 2;
                  "Mod+3".action = focus-workspace 3;
                  "Mod+4".action = focus-workspace 4;
                  "Mod+5".action = focus-workspace 5;
                  "Mod+6".action = focus-workspace 6;
                  "Mod+7".action = focus-workspace 7;
                  "Mod+8".action = focus-workspace 8;
                  "Mod+9".action = focus-workspace 9;
                  "Mod+Ctrl+p".action = spawn "1password" "--quick-acces";
                  "Mod+Down".action = focus-window-or-workspace-down;
                  "Mod+Equal".action = set-column-width "+10%";
                  "Mod+Escape".action = spawn "noctalia" "msg" "panel-toggle" "session";
                  "Mod+Left".action = focus-column-or-monitor-left;
                  "Mod+Minus".action = set-column-width "-10%";
                  "Mod+Return".action = sh "exec kitty -o confirm_os_window_close=0";
                  "Mod+Right".action = focus-column-or-monitor-right;
                  "Mod+Shift+0".action = move-column-to-index 0;
                  "Mod+Shift+1".action = move-column-to-index 1;
                  "Mod+Shift+2".action = move-column-to-index 2;
                  "Mod+Shift+3".action = move-column-to-index 3;
                  "Mod+Shift+4".action = move-column-to-index 4;
                  "Mod+Shift+5".action = move-column-to-index 5;
                  "Mod+Shift+6".action = move-column-to-index 6;
                  "Mod+Shift+7".action = move-column-to-index 7;
                  "Mod+Shift+8".action = move-column-to-index 8;
                  "Mod+Shift+9".action = move-column-to-index 9;
                  "Mod+Shift+Down".action = move-window-down-or-to-workspace-down;
                  "Mod+Shift+Escape".action = spawn "kitty" "-o" "confirm_os_window_close=0" "btm";
                  "Mod+Shift+Left".action = move-column-left-or-to-monitor-left;
                  "Mod+Shift+Right".action = move-column-right-or-to-monitor-right;
                  "Mod+Shift+Space".action = toggle-window-floating;
                  "Mod+Shift+Up".action = move-window-up-or-to-workspace-up;
                  "Mod+Shift+a".action = sh "exec emacsclient -ce '(swarsel/open-calendar)'";
                  "Mod+Shift+c".action = spawn "qalculate-gtk";
                  "Mod+Shift+f".action = fullscreen-window;
                  "Mod+Shift+m".action = sh "exec emacsclient -ce '(mu4e)'";
                  "Mod+Shift+o".action = spawn "pass-fuzzel" "--otp" "--type";
                  "Mod+Shift+p".action = spawn "pass-fuzzel" "--type";
                  "Mod+Shift+s".action.screenshot-window = {
                    write-to-disk = true;
                  };
                  "Mod+Shift+t".action = toggle-window-rule-opacity;
                  "Mod+Space".action = sh "exec noctalia msg panel-toggle launcher";
                  "Mod+Up".action = focus-window-or-workspace-up;
                  "Mod+a".action = spawn "swarselcheck-niri" "-s";
                  "Mod+c".action = sh "exec emacsclient -ce '(org-capture)'";
                  "Mod+d".action = spawn "swarselcheck-niri" "-d";
                  "Mod+e".action = sh "exec emacsclient -nquc -a emacs -e '(dashboard-open)'";
                  "Mod+f".action = sh "exec glide";
                  "Mod+h".action = sh "hyprpicker | wl-copy";
                  "Mod+i".action = spawn "noctalia" "msg" "panel-toggle" "launcher" "/emo";
                  "Mod+m".action = focus-workspace-previous;
                  "Mod+o".action = spawn "pass-fuzzel" "--otp";
                  "Mod+p".action = spawn "pass-fuzzel";
                  "Mod+q".action = sh "niri msg action close-window";
                  "Mod+s".action.screenshot = {
                    show-pointer = false;
                  };
                  "Mod+t".action = sh "exec emacsclient -ce '(org-agenda)'";
                  "Mod+w".action = spawn "swarselcheck-niri" "-e";
                  "Mod+x".action = spawn "swarselcheck-niri" "-k";
                  "Mod+z".action = spawn "noctalia" "msg" "bar-toggle";
                  "XF86AudioLowerVolume".action = spawn "noctalia" "msg" "volume-down";
                  "XF86AudioMute".action = spawn "noctalia" "msg" "volume-mute";
                  "XF86AudioNext".action = spawn "noctalia" "msg" "media" "next";
                  "XF86AudioPlay".action = spawn "noctalia" "msg" "media" "toggle";
                  "XF86AudioPrev".action = spawn "noctalia" "msg" "media" "previous";
                  "XF86AudioRaiseVolume".action = spawn "noctalia" "msg" "volume-up";
                  "XF86Display".action = spawn "wl-mirror" "eDP-1";
                  "XF86MonBrightnessDown".action = spawn "noctalia" "msg" "brightness-down";
                  "XF86MonBrightnessUp".action = spawn "noctalia" "msg" "brightness-up";
                };
              cursor = {
                hide-after-inactive-ms = 2000;
                hide-when-typing = true;
              };
              debug = {
                honor-xdg-activation-with-invalid-serial = [ ];
              };
              environment = vars.waylandSessionVariables // {
                DISPLAY = ":0";
                EDITOR = "emacsclient -c";
                QT_QPA_PLATFORM = lib.mkForce "wayland";
              };
              gestures.hot-corners.enable = false;
              hotkey-overlay.skip-at-startup = true;
              input = {
                keyboard = {
                  xkb = {
                    layout = "us";
                    variant = "altgr-intl";
                  };
                };
                mod-key = "Super";
                mouse = {
                  natural-scroll = false;
                };
                touchpad = {
                  enable = true;
                  click-method = "clickfinger";
                  disabled-on-external-mouse = true;
                  drag = true;
                  drag-lock = false;
                  dwt = true;
                  dwtp = true;
                  natural-scroll = true;
                  scroll-method = "two-finger";
                  tap = true;
                  tap-button-map = "left-right-middle";
                };
              };
              layer-rules = [
                {
                  block-out-from = "screen-capture";
                  matches = [ { namespace = "^notificatioans$"; } ];
                }
                {
                  matches = [ { namespace = "^wallpaper$"; } ];
                  place-within-backdrop = true;
                }
                {
                  matches = [ { namespace = "^noctalia-overview*"; } ];
                  place-within-backdrop = true;
                }
              ];
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
              prefer-no-csd = true;
              screenshot-path = "~/Pictures/Screenshots/screenshot_%Y-%m-%d-%H%M%S.png";
              spawn-at-startup = [
                {
                  argv = [
                    "systemctl"
                    "--user"
                    "restart"
                    "noctalia-shell.target"
                  ];
                }
              ];
              window-rules = [
                {
                  clip-to-geometry = true;
                  default-column-width = {
                    proportion = 0.5;
                  };
                  geometry-corner-radius = {
                    bottom-left = 5.0;
                    bottom-right = 5.0;
                    top-left = 5.0;
                    top-right = 5.0;
                  };
                  matches = [ { app-id = ".*"; } ];
                  opacity = 0.95;
                  shadow = {
                    enable = true;
                    draw-behind-window = true;
                  };
                }
                {
                  matches = [ { app-id = "at.yrlf.wl_mirror"; } ];
                  opacity = 1.0;
                }
                {
                  matches = [ { app-id = "Gimp"; } ];
                  opacity = 1.0;
                }
                {
                  matches = [
                    { app-id = "^firefox$"; }
                    { app-id = "^glide$"; }
                  ];
                  opacity = 0.95;
                }
                {
                  default-column-width = {
                    proportion = 0.9;
                  };
                  matches = [ { app-id = "^special.*"; } ];
                  open-on-workspace = "Scratchpad";
                }
                {
                  matches = [ { app-id = "chromium-browser"; } ];
                  opacity = 0.99;
                }
                {
                  matches = [ { app-id = "^qalculate-gtk$"; } ];
                  open-floating = true;
                }
                {
                  matches = [ { app-id = "^blueman$"; } ];
                  open-floating = true;
                }
                {
                  matches = [ { app-id = "^pavucontrol$"; } ];
                  open-floating = true;
                }
                {
                  matches = [ { app-id = "^syncthingtray$"; } ];
                  open-floating = true;
                }
                {
                  block-out-from = "screen-capture";
                  default-column-width = {
                    proportion = 0.5;
                  };
                  matches = [ { app-id = "^Element$"; } ];
                  open-floating = true;
                }
                {
                  block-out-from = "screen-capture";
                  default-column-width = {
                    proportion = 0.5;
                  };
                  matches = [ { title = "^Element"; } ];
                  open-floating = true;
                }
                {
                  block-out-from = "screen-capture";
                  default-column-width = {
                    proportion = 0.5;
                  };
                  matches = [ { app-id = "^vesktop$"; } ];
                  open-floating = true;
                }
                {
                  matches = [ { app-id = "^com.nextcloud.desktopclient.nextcloud$"; } ];
                  open-floating = true;
                }
                {
                  block-out-from = "screen-capture";
                  excludes = [
                    { app-id = "^firefox$"; }
                    { app-id = "^glide$"; }
                    { app-id = "^emacs$"; }
                    { app-id = "^kitty$"; }
                  ];
                  matches = [ { title = ".*1Password.*"; } ];
                  open-floating = true;
                }
                {
                  matches = [ { title = "(?:Open|Save) (?:File|Folder|As)"; } ];
                  open-floating = true;
                }
                {
                  matches = [ { title = "^Add$"; } ];
                  open-floating = true;
                }
                {
                  matches = [ { title = "^Picture-in-Picture$"; } ];
                  open-floating = true;
                }
                {
                  matches = [ { title = "Syncthing Tray"; } ];
                  open-floating = true;
                }
                {
                  matches = [ { title = "^Emacs Popup Frame$"; } ];
                  open-floating = true;
                }
                {
                  matches = [ { title = "^Emacs Popup Anchor$"; } ];
                  open-floating = true;
                }
                {
                  default-column-width = {
                    proportion = 0.5;
                  };
                  matches = [ { app-id = "^spotifytui$"; } ];
                  open-floating = true;
                }
                {
                  default-column-width = {
                    proportion = 0.5;
                  };
                  matches = [ { app-id = "^kittyterm$"; } ];
                  open-floating = true;
                }
              ];
              xwayland-satellite = {
                enable = true;
                path = "${lib.getExe pkgs.xwayland-satellite-unstable}";
              };
            };
          };
          home = {
            packages = [
              pkgs.nirius
            ];
            sessionVariables = {
              EDITOR = lib.mkDefault "e-niri -w";
            };
          };
          xdg.portal = {
            config.niri = {
              default = [
                "gtk"
                "gnome"
              ];
              "org.freedesktop.impl.portal.Access" = [ "gtk" ];
              "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
              "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
              "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
              "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
              "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
            };
            enable = true;
            extraPortals = [
              pkgs.gnome-keyring
              pkgs.xdg-desktop-portal-gtk
              pkgs.xdg-desktop-portal-gnome
            ];
            xdgOpenUsePortal = true;
          };

        };
      };
    nixos.niri = { inputs, lib, ... }: {
      imports = lib.optionals (inputs ? niritiling) [
        inputs.niri-flake.nixosModules.niri
        inputs.niritiling.nixosModules.default
        ({ config, pkgs, ... }: {
          services.niritiling = {
            enable = true;
            resizeColumns = true;
          };
          programs = {
            niri = {
              enable = true;
              package = pkgs.niri-stable;
            };
          };
          environment.systemPackages = with pkgs; [
            wl-clipboard
            wayland-utils
            libsecret
            cage
            gamescope
            xwayland-satellite-unstable
          ];
          home-manager.users.${config.swarselsystems.mainUser}.imports = [
            fmods.homeManager.niri
          ];
          niri-flake.cache.enable = true;
        })
      ];
    };
  };
}
