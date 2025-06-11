{ self, config, pkgs, lib, nixosConfig, ... }:
let
  inherit (config.swarselsystems) homeDir;
  inherit (nixosConfig.repo.secrets.local.work) user1 user1Long user2 user2Long user3 user3Long user4 path1 loc1 loc2 site1 site2 site3 site4 site5 site6 site7 lifecycle1 lifecycle2 domain1 domain2 gitMail;
in
{
  options.swarselsystems.modules.optional.work = lib.mkEnableOption "optional work settings";
  config = lib.mkIf config.swarselsystems.modules.optional.work {
    home.packages = with pkgs; [
      stable.teams-for-linux
      shellcheck
      dig
      docker
      postman
      rclone
      stable.awscli2
      libguestfs-with-appliance
      stable.prometheus.cli
      tigervnc
      openstackclient
    ];

    home.sessionVariables = {
      DOCUMENT_DIR_PRIV = lib.mkForce "${homeDir}/Documents/Private";
      DOCUMENT_DIR_WORK = lib.mkForce "${homeDir}/Documents/Work";
    };

    wayland.windowManager.sway.config = {
      output = {
        "Applied Creative Technology Transmitter QUATTRO201811" = {
          bg = "${self}/wallpaper/navidrome.png ${config.stylix.imageScalingMode}";
        };
        "Hewlett Packard HP Z24i CN44250RDT" = {
          bg = "${self}/wallpaper/op6wp.png ${config.stylix.imageScalingMode}";
        };
        "HP Inc. HP 732pk CNC4080YL5" = {
          bg = "${self}/wallpaper/botanicswp.png ${config.stylix.imageScalingMode}";
        };
      };
    };

    stylix.targets.firefox.profileNames = [
      "${user1}"
      "${user2}"
      "${user3}"
      "work"
    ];

    programs = {
      git.userEmail = lib.mkForce gitMail;

      zsh = {
        shellAliases = {
          dssh = "ssh -l ${user1Long}";
          cssh = "ssh -l ${user2Long}";
          wssh = "ssh -l ${user3Long}";
        };
        cdpath = [
          "~/Documents/Work"
        ];
        dirHashes = {
          d = "$HOME/.dotfiles";
          w = "$HOME/Documents/Work";
          s = "$HOME/.dotfiles/secrets";
          pr = "$HOME/Documents/Private";
          ac = path1;
        };
      };

      ssh = {
        matchBlocks = {
          "${loc1}" = {
            hostname = "${loc1}.${domain2}";
            user = user4;
          };
          "${loc1}.stg" = {
            hostname = "${loc1}.${lifecycle1}.${domain2}";
            user = user4;
          };
          "${loc1}.staging" = {
            hostname = "${loc1}.${lifecycle1}.${domain2}";
            user = user4;
          };
          "${loc1}.dev" = {
            hostname = "${loc1}.${lifecycle2}.${domain2}";
            user = user4;
          };
          "${loc2}" = {
            hostname = "${loc2}.${domain1}";
            user = user1Long;
          };
          "${loc2}.stg" = {
            hostname = "${loc2}.${lifecycle1}.${domain2}";
            user = user1Long;
          };
          "${loc2}.staging" = {
            hostname = "${loc2}.${lifecycle1}.${domain2}";
            user = user1Long;
          };
          "*.${domain1}" = {
            user = user1Long;
          };
        };
      };

      firefox = {
        profiles =
          let
            isDefault = false;
          in
          {
            "${user1}" = lib.recursiveUpdate
              {
                inherit isDefault;
                id = 1;
                settings = {
                  "browser.startup.homepage" = "${site1}|${site2}";
                };
              }
              config.swarselsystems.firefox;
            "${user2}" = lib.recursiveUpdate
              {
                inherit isDefault;
                id = 2;
                settings = {
                  "browser.startup.homepage" = "${site3}";
                };
              }
              config.swarselsystems.firefox;
            "${user3}" = lib.recursiveUpdate
              {
                inherit isDefault;
                id = 3;
              }
              config.swarselsystems.firefox;
            work = lib.recursiveUpdate
              {
                inherit isDefault;
                id = 4;
                settings = {
                  "browser.startup.homepage" = "${site4}|${site5}|${site6}|${site7}";
                };
              }
              config.swarselsystems.firefox;
          };
      };

      chromium = {
        enable = true;
        package = pkgs.chromium;

        extensions = [
          # 1password
          "gejiddohjgogedgjnonbofjigllpkmbf"
          # dark reader
          "eimadpbcbfnmbkopoojfekhnkhdbieeh"
          # ublock origin
          "cjpalhdlnbpafiamejdnhcphjbkeiagm"
          # i still dont care about cookies
          "edibdbjcniadpccecjdfdjjppcpchdlm"
          # browserpass
          "naepdomgkenhinolocfifgehidddafch"
        ];
      };
    };

    services = {
      kanshi = {
        settings = [
          {
            # seminary room
            output = {
              criteria = "Applied Creative Technology Transmitter QUATTRO201811";
              scale = 1.0;
              mode = "1280x720";
            };
          }
          {
            # work main screen
            output = {
              criteria = "HP Inc. HP 732pk CNC4080YL5";
              scale = 1.0;
              mode = "3840x2160";
            };
          }
          {
            # work side screen
            output = {
              criteria = "Hewlett Packard HP Z24i CN44250RDT";
              scale = 1.0;
              mode = "1920x1200";
              transform = "270";
            };
          }
          {
            profile = {
              name = "lidopen";
              outputs = [
                {
                  criteria = config.swarselsystems.sharescreen;
                  status = "enable";
                  scale = 1.5;
                  position = "1462,0";
                }
                {
                  criteria = "HP Inc. HP 732pk CNC4080YL5";
                  scale = 1.4;
                  mode = "3840x2160";
                  position = "-1280,0";
                }
                {
                  criteria = "Hewlett Packard HP Z24i CN44250RDT";
                  scale = 1.0;
                  mode = "1920x1200";
                  transform = "90";
                  position = "-2480,0";
                }
              ];
            };
          }
          {
            profile = {
              name = "lidopen";
              outputs = [
                {
                  criteria = config.swarselsystems.sharescreen;
                  status = "enable";
                  scale = 1.7;
                  position = "2560,0";
                }
                {
                  criteria = "Applied Creative Technology Transmitter QUATTRO201811";
                  scale = 1.0;
                  mode = "1280x720";
                  position = "10000,10000";
                }
              ];
            };
          }
          {
            profile = {
              name = "lidclosed";
              outputs = [
                {
                  criteria = config.swarselsystems.sharescreen;
                  status = "disable";
                }
                {
                  criteria = "HP Inc. HP 732pk CNC4080YL5";
                  scale = 1.4;
                  mode = "3840x2160";
                  position = "-1280,0";
                }
                {
                  criteria = "Hewlett Packard HP Z24i CN44250RDT";
                  scale = 1.0;
                  mode = "1920x1200";
                  transform = "270";
                  position = "-2480,0";
                }
              ];
            };
          }
          {
            profile = {
              name = "lidclosed";
              outputs = [
                {
                  criteria = config.swarselsystems.sharescreen;
                  status = "disable";
                }
                {
                  criteria = "Applied Creative Technology Transmitter QUATTRO201811";
                  scale = 1.0;
                  mode = "1280x720";
                  position = "10000,10000";
                }
              ];
            };
          }
        ];
      };
    };

    xdg = {
      mimeApps = {
        defaultApplications = {
          "x-scheme-handler/msteams" = [ "teams-for-linux.desktop" ];
        };
      };
      desktopEntries =
        let
          terminal = false;
          categories = [ "Application" ];
          icon = "firefox";
        in
        {
          firefox_work = {
            name = "Firefox (work)";
            genericName = "Firefox work";
            exec = "firefox -p work";
            inherit terminal categories icon;
          };
          "firefox_${user1}" = {
            name = "Firefox (${user1})";
            genericName = "Firefox ${user1}";
            exec = "firefox -p ${user4}";
            inherit terminal categories icon;
          };

          "firefox_${user2}" = {
            name = "Firefox (${user2})";
            genericName = "Firefox ${user2}";
            exec = "firefox -p ${user2}";
            inherit terminal categories icon;
          };

          "firefox_${user3}" = {
            name = "Firefox (${user3})";
            genericName = "Firefox ${user3}";
            exec = "firefox -p ${user3}";
            inherit terminal categories icon;
          };


        };
    };
    swarselsystems = {
      startup = [
        { command = "nextcloud --background"; }
        { command = "vesktop --start-minimized --enable-speech-dispatcher --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime"; }
        { command = "element-desktop --hidden  --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-driver-bug-workarounds"; }
        { command = "ANKI_WAYLAND=1 anki"; }
        { command = "OBSIDIAN_USE_WAYLAND=1 obsidian"; }
        { command = "nm-applet"; }
        { command = "feishin"; }
        { command = "teams-for-linux"; }
        { command = "1password"; }
      ];
      monitors = {
        main = {
          name = "BOE 0x0BC9 Unknown";
          mode = "2560x1600"; # TEMPLATE
          scale = "1";
          position = "2560,0";
          workspace = "15:L";
          output = "eDP-2";
        };
        homedesktop = {
          name = "Philips Consumer Electronics Company PHL BDM3270 AU11806002320";
          mode = "2560x1440";
          scale = "1";
          position = "0,0";
          workspace = "1:一";
          output = "DP-11";
        };
        work_back_middle = {
          name = "LG Electronics LG Ultra HD 0x000305A6";
          mode = "2560x1440";
          scale = "1";
          position = "5120,0";
          workspace = "1:一";
          output = "DP-10";
        };
        work_front_left = {
          name = "LG Electronics LG Ultra HD 0x0007AB45";
          mode = "3840x2160";
          scale = "1";
          position = "5120,0";
          workspace = "1:一";
          output = "DP-7";
        };
        work_back_right = {
          name = "HP Inc. HP Z32 CN41212T55";
          mode = "3840x2160";
          scale = "1";
          position = "5120,0";
          workspace = "1:一";
          output = "DP-3";
        };
        work_middle_middle_main = {
          name = "HP Inc. HP 732pk CNC4080YL5";
          mode = "3840x2160";
          scale = "1";
          position = "-1280,0";
          workspace = "11:M";
          output = "DP-8";
        };
        work_middle_middle_side = {
          name = "Hewlett Packard HP Z24i CN44250RDT";
          mode = "1920x1200";
          transform = "270";
          scale = "1";
          position = "-2480,0";
          workspace = "12:S";
          output = "DP-9";
        };
        work_seminary = {
          name = "Applied Creative Technology Transmitter QUATTRO201811";
          mode = "1280x720";
          scale = "1";
          position = "10000,10000"; # i.e. this screen is inaccessible by moving the mouse
          workspace = "14:T";
          output = "DP-4";
        };
      };
      inputs = {
        "1133:45081:MX_Master_2S_Keyboard" = {
          xkb_layout = "us";
          xkb_variant = "altgr-intl";
        };
        # "2362:628:PIXA3854:00_093A:0274_Touchpad" = {
        #   dwt = "enabled";
        #   tap = "enabled";
        #   natural_scroll = "enabled";
        #   middle_emulation = "enabled";
        #   drag_lock = "disabled";
        # };
        "1133:50504:Logitech_USB_Receiver" = {
          xkb_layout = "us";
          xkb_variant = "altgr-intl";
        };
        "1133:45944:MX_KEYS_S" = {
          xkb_layout = "us";
          xkb_variant = "altgr-intl";
        };
      };
      keybindings = {
        "Mod4+Ctrl+Shift+p" = "exec screenshare";
      };

    };
  };

}
