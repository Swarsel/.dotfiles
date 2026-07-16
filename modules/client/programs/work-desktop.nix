{
  flake.modules.homeManager.work-desktop =
    {
      self,
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    {
      config = {
        swarselsystems = {
          inputs = {
            "1133:45081:MX_Master_2S_Keyboard" = {
              xkb_layout = "us";
              xkb_variant = "altgr-intl";
            };
            "1133:45944:MX_KEYS_S" = {
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
          };
          monitors = {
            work_back_middle = rec {
              mode = "2560x1440";
              name = "LG Electronics LG Ultra HD 0x000305A6";
              # output = "DP-10";
              output = name;
              position = "5120,0";
              scale = "1";
              workspace = "1:一";
            };
            work_front_left = rec {
              mode = "3840x2160";
              name = "LG Electronics LG Ultra HD 0x0007AB45";
              # output = "DP-7";
              output = name;
              position = "5120,0";
              scale = "1";
              workspace = "1:一";
            };
            work_middle_middle_main = rec {
              mode = "3840x2160";
              name = "HP Inc. HP Z32 CN41212T55";
              # output = "DP-3";
              output = name;
              position = "-1280,0";
              scale = "1";
              workspace = "1:一";
            };
            work_middle_middle_old = rec {
              mode = "1920x1200";
              name = "Hewlett Packard HP Z24i CN44250RDT";
              # output = "DP-9";
              output = name;
              position = "-2480,0";
              scale = "1";
              transform = "270";
              workspace = "12:S";
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
              mode = "3840x2160";
              name = "HP Inc. HP 732pk CNC4080YL5";
              # output = "DP-8";
              output = name;
              position = "-3440,-1050";
              scale = "1";
              transform = "270";
              workspace = "12:S";
            };
            work_seminary = rec {
              mode = "1280x720";
              name = "Applied Creative Technology Transmitter QUATTRO201811";
              # output = "DP-4";
              output = name;
              position = "10000,10000"; # i.e. this screen is inaccessible by moving the mouse
              scale = "1";
              workspace = "14:T";
            };
          };
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
        };
        services = {

          kanshi = {
            settings = [
              {
                # seminary room
                output = {
                  criteria = "Applied Creative Technology Transmitter QUATTRO201811";
                  mode = "1280x720";
                  scale = 1.0;
                };
              }
              {
                # work side screen
                output = {
                  criteria = "HP Inc. HP 732pk CNC4080YL5";
                  mode = "3840x2160";
                  scale = 1.0;
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
                  mode = "3840x2160";
                  scale = 1.0;
                };
              }
              {
                profile = {
                  exec = [
                    "${pkgs.swaybg}/bin/swaybg --output '${config.swarselsystems.sharescreen}' --image ${config.swarselsystems.wallpaper} --mode ${config.stylix.imageScalingMode}"
                    "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP Z32 CN41212T55' --image ${self}/files/wallpaper/landscape/botanicswp.png --mode ${config.stylix.imageScalingMode}"
                    "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP 732pk CNC4080YL5' --image ${self}/files/wallpaper/portrait/op6wp.png --mode ${config.stylix.imageScalingMode}"
                  ];
                  name = "lidopen";
                  outputs = [
                    {
                      criteria = config.swarselsystems.sharescreen;
                      position = "2560,0";
                      scale = 1.5;
                      status = "enable";
                    }
                    {
                      criteria = "HP Inc. HP 732pk CNC4080YL5";
                      mode = "3840x2160";
                      position = "-3440,-1050";
                      scale = 1.0;
                      transform = "270";
                    }
                    {
                      criteria = "HP Inc. HP Z32 CN41212T55";
                      mode = "3840x2160";
                      position = "-1280,0";
                      scale = 1.0;
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
                    exec = [
                      "${pkgs.swaybg}/bin/swaybg --output '${config.swarselsystems.sharescreen}' --image ${config.swarselsystems.wallpaper} --mode ${config.stylix.imageScalingMode}"
                      "${pkgs.swaybg}/bin/swaybg --output '${monitor}' --image ${self}/files/wallpaper/services/navidrome.png --mode ${config.stylix.imageScalingMode}"
                      "${pkgs.kanshare}/bin/kanshare ${config.swarselsystems.sharescreen} '${monitor}'"
                    ];
                    name = "lidopen";
                    outputs = [
                      {
                        criteria = config.swarselsystems.sharescreen;
                        position = "2560,0";
                        scale = 1.7;
                        status = "enable";
                      }
                      {
                        criteria = "Applied Creative Technology Transmitter QUATTRO201811";
                        mode = "1280x720";
                        position = "10000,10000";
                        scale = 1.0;
                      }
                    ];
                  };
              }
              {
                profile = {
                  exec = [
                    "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP Z32 CN41212T55'  --image ${self}/files/wallpaper/landscape/botanicswp.png --mode ${config.stylix.imageScalingMode}"
                    "${pkgs.swaybg}/bin/swaybg --output 'HP Inc. HP 732pk CNC4080YL5' --image ${self}/files/wallpaper/portrait/op6wp.png --mode ${config.stylix.imageScalingMode}"
                  ];
                  name = "lidclosed";
                  outputs = [
                    {
                      criteria = config.swarselsystems.sharescreen;
                      status = "disable";
                    }
                    {
                      criteria = "HP Inc. HP 732pk CNC4080YL5";
                      mode = "3840x2160";
                      position = "-3440,-1050";
                      scale = 1.0;
                      transform = "270";
                    }
                    {
                      criteria = "HP Inc. HP Z32 CN41212T55";
                      mode = "3840x2160";
                      position = "-1280,0";
                      scale = 1.0;
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
                    exec = [
                      "${pkgs.swaybg}/bin/swaybg --output '${monitor}' --image ${self}/files/wallpaper/services/navidrome.png --mode ${config.stylix.imageScalingMode}"
                    ];
                    name = "lidclosed";
                    outputs = [
                      {
                        criteria = config.swarselsystems.sharescreen;
                        status = "disable";
                      }
                      {
                        criteria = "Applied Creative Technology Transmitter QUATTRO201811";
                        mode = "1280x720";
                        position = "10000,10000";
                        scale = 1.0;
                      }
                    ];
                  };
              }
            ];
          };
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
                    inherit exec;
                    name = "work-internal-on";
                    output = [
                      {
                        enable = true;
                        match = config.swarselsystems.sharescreen;
                        position = "2560,0";
                        scale = 1.7;
                      }
                      {
                        enable = true;
                        match = workRight;
                        mode = "3840x2160@60Hz";
                        position = "-1280,0";
                        scale = 1.0;
                      }
                      {
                        enable = true;
                        match = workLeft;
                        mode = "3840x2160@60Hz";
                        position = "-3440,-1050";
                        scale = 1.0;
                        transform = "270";
                      }
                    ];
                  }
                  {
                    inherit exec;
                    name = "work-internal-off";
                    output = [
                      {
                        enable = false;
                        match = config.swarselsystems.sharescreen;
                        position = "2560,0";
                        scale = 1.7;
                      }
                      {
                        enable = true;
                        match = workRight;
                        mode = "3840x2160@60Hz";
                        position = "-1280,0";
                        scale = 1.0;
                      }
                      {
                        enable = true;
                        match = workLeft;
                        mode = "3840x2160@60Hz";
                        position = "-3440,-1050";
                        scale = 1.0;
                        transform = "270";
                      }
                    ];
                  }

                ];
              };
          };
        };
        stylix = {
          targets.firefox.profileNames =
            let
              inherit (confLib.getConfig.repo.secrets.work) user1 user2 user3;
            in
            lib.mkIf (!config.programs.glide-browser.enable) [
              "${user1}"
              "${user2}"
              "${user3}"
            ];
        };
        wayland.windowManager.sway =
          let
            inherit (confLib.getConfig.repo.secrets.work)
              domain1
              mailAddress
              user1
              user1Long
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
      };
    };
}
