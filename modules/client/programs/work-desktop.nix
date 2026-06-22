{
  flake.modules.homeManager.work-desktop =
    {
      self,
      config,
      pkgs,
      confLib,
      ...
    }:
    {
      config = {
        wayland.windowManager.sway =
          let
            inherit (confLib.getConfig.repo.secrets.local.work)
              user1
              user1Long
              domain1
              mailAddress
              ;
          in
          {
            config = {
              keybindings =
                let
                  inherit (config.wayland.windowManager.sway.config) modifier;
                in
                {
                  "${modifier}+Shift+d" =
                    "exec ${pkgs.quickpass}/bin/quickpass work/adm/${user1}/${user1Long}@${domain1}";
                  "${modifier}+Shift+i" = "exec ${pkgs.quickpass}/bin/quickpass work/${mailAddress}";
                };
            };
          };

        stylix = {
          targets.firefox.profileNames =
            let
              inherit (confLib.getConfig.repo.secrets.local.work) user1 user2 user3;
            in
            [
              "${user1}"
              "${user2}"
              "${user3}"
              "work"
            ];
        };

        services = {

          shikane = {
            settings =
              let
                workRight = [
                  "m=HP Z32"
                  "s=CN41212T55"
                  "v=HP Inc."
                ];
                workLeft = [
                  "m=HP 732pk"
                  "s=CNC4080YL5"
                  "v=HP Inc."
                ];
                exec = [ "notify-send shikane \"Profile $SHIKANE_PROFILE_NAME has been applied\"" ];
              in
              {
                profile = [

                  {
                    name = "work-internal-on";
                    inherit exec;
                    output = [
                      {
                        match = config.swarselsystems.sharescreen;
                        enable = true;
                        scale = 1.7;
                        position = "2560,0";
                      }
                      {
                        match = workRight;
                        enable = true;
                        scale = 1.0;
                        mode = "3840x2160@60Hz";
                        position = "-1280,0";
                      }
                      {
                        match = workLeft;
                        enable = true;
                        scale = 1.0;
                        transform = "270";
                        mode = "3840x2160@60Hz";
                        position = "-3440,-1050";
                      }
                    ];
                  }
                  {
                    name = "work-internal-off";
                    inherit exec;
                    output = [
                      {
                        match = config.swarselsystems.sharescreen;
                        enable = false;
                        scale = 1.7;
                        position = "2560,0";
                      }
                      {
                        match = workRight;
                        enable = true;
                        scale = 1.0;
                        mode = "3840x2160@60Hz";
                        position = "-1280,0";
                      }
                      {
                        match = workLeft;
                        enable = true;
                        scale = 1.0;
                        transform = "270";
                        mode = "3840x2160@60Hz";
                        position = "-3440,-1050";
                      }
                    ];
                  }

                ];
              };
          };
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
                # work side screen
                output = {
                  criteria = "HP Inc. HP 732pk CNC4080YL5";
                  scale = 1.0;
                  mode = "3840x2160";
                  transform = "270";
                };
              }
              # {
              #   # work side screen
              #   output = {
              #     criteria = "Hewlett Packard HP Z24i CN44250RDT";
              #     scale = 1.0;
              #     mode = "1920x1200";
              #     transform = "270";
              #   };
              # }
              {
                # work main screen
                output = {
                  criteria = "HP Inc. HP Z32 CN41212T55";
                  scale = 1.0;
                  mode = "3840x2160";
                };
              }
              {
                profile = {
                  name = "lidopen";
                  exec = [
                    "${pkgs.swaybg}/bin/swaybg --output '${config.swarselsystems.sharescreen}' --image ${config.swarselsystems.wallpaper} --mode ${config.stylix.imageScalingMode}"
                    "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP Z32 CN41212T55' --image ${self}/files/wallpaper/landscape/botanicswp.png --mode ${config.stylix.imageScalingMode}"
                    "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP 732pk CNC4080YL5' --image ${self}/files/wallpaper/portrait/op6wp.png --mode ${config.stylix.imageScalingMode}"
                  ];
                  outputs = [
                    {
                      criteria = config.swarselsystems.sharescreen;
                      status = "enable";
                      scale = 1.5;
                      position = "2560,0";
                    }
                    {
                      criteria = "HP Inc. HP 732pk CNC4080YL5";
                      scale = 1.0;
                      mode = "3840x2160";
                      position = "-3440,-1050";
                      transform = "270";
                    }
                    {
                      criteria = "HP Inc. HP Z32 CN41212T55";
                      scale = 1.0;
                      mode = "3840x2160";
                      position = "-1280,0";
                    }
                  ];
                };
              }
              {
                profile =
                  let
                    monitor = "Applied Creative Technology Transmitter QUATTRO201811";
                  in
                  {
                    name = "lidopen";
                    exec = [
                      "${pkgs.swaybg}/bin/swaybg --output '${config.swarselsystems.sharescreen}' --image ${config.swarselsystems.wallpaper} --mode ${config.stylix.imageScalingMode}"
                      "${pkgs.swaybg}/bin/swaybg --output '${monitor}' --image ${self}/files/wallpaper/services/navidrome.png --mode ${config.stylix.imageScalingMode}"
                      "${pkgs.kanshare}/bin/kanshare ${config.swarselsystems.sharescreen} '${monitor}'"
                    ];
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
                  exec = [
                    "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP Z32 CN41212T55'  --image ${self}/files/wallpaper/landscape/botanicswp.png --mode ${config.stylix.imageScalingMode}"
                    "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP 732pk CNC4080YL5' --image ${self}/files/wallpaper/portrait/op6wp.png --mode ${config.stylix.imageScalingMode}"
                  ];
                  outputs = [
                    {
                      criteria = config.swarselsystems.sharescreen;
                      status = "disable";
                    }
                    {
                      criteria = "HP Inc. HP 732pk CNC4080YL5";
                      scale = 1.0;
                      mode = "3840x2160";
                      position = "-3440,-1050";
                      transform = "270";
                    }
                    {
                      criteria = "HP Inc. HP Z32 CN41212T55";
                      scale = 1.0;
                      mode = "3840x2160";
                      position = "-1280,0";
                    }
                  ];
                };
              }
              {
                profile =
                  let
                    monitor = "Applied Creative Technology Transmitter QUATTRO201811";
                  in
                  {
                    name = "lidclosed";
                    exec = [
                      "${pkgs.swaybg}/bin/swaybg --output '${monitor}' --image ${self}/files/wallpaper/services/navidrome.png --mode ${config.stylix.imageScalingMode}"
                    ];
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

        swarselsystems = {
          startup = [
            # { command = "nextcloud --background"; }
            # { command = "vesktop --start-minimized --enable-speech-dispatcher --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime"; }
            # { command = "element-desktop --hidden  --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-driver-bug-workarounds"; }
            # { command = "anki"; }
            # { command = "obsidian"; }
            # { command = "nm-applet"; }
            # { command = "feishin"; }
            # { command = "teams-for-linux --disableGpu=true --minimized=true --trayIconEnabled=true"; }
            # { command = "1password"; }
          ];
          monitors = {
            work_back_middle = rec {
              name = "LG Electronics LG Ultra HD 0x000305A6";
              mode = "2560x1440";
              scale = "1";
              position = "5120,0";
              workspace = "1:一";
              # output = "DP-10";
              output = name;
            };
            work_front_left = rec {
              name = "LG Electronics LG Ultra HD 0x0007AB45";
              mode = "3840x2160";
              scale = "1";
              position = "5120,0";
              workspace = "1:一";
              # output = "DP-7";
              output = name;
            };
            work_middle_middle_main = rec {
              name = "HP Inc. HP Z32 CN41212T55";
              mode = "3840x2160";
              scale = "1";
              position = "-1280,0";
              workspace = "1:一";
              # output = "DP-3";
              output = name;
            };
            # work_middle_middle_main = rec {
            #   name = "HP Inc. HP 732pk CNC4080YL5";
            #   mode = "3840x2160";
            #   scale = "1";
            #   position = "-1280,0";
            #   workspace = "11:M";
            #   # output = "DP-8";
            #   output = name;
            # };
            work_middle_middle_side = rec {
              name = "HP Inc. HP 732pk CNC4080YL5";
              mode = "3840x2160";
              transform = "270";
              scale = "1";
              position = "-3440,-1050";
              workspace = "12:S";
              # output = "DP-8";
              output = name;
            };
            work_middle_middle_old = rec {
              name = "Hewlett Packard HP Z24i CN44250RDT";
              mode = "1920x1200";
              transform = "270";
              scale = "1";
              position = "-2480,0";
              workspace = "12:S";
              # output = "DP-9";
              output = name;
            };
            work_seminary = rec {
              name = "Applied Creative Technology Transmitter QUATTRO201811";
              mode = "1280x720";
              scale = "1";
              position = "10000,10000"; # i.e. this screen is inaccessible by moving the mouse
              workspace = "14:T";
              # output = "DP-4";
              output = name;
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
        };
      };
    };
}
