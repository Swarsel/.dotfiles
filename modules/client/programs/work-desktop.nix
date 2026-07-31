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
    let
      inherit (config.swarselsystems) monitors;
    in
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
            "1133:50504:Logitech_USB_Receiver" = {
              xkb_layout = "us";
              xkb_variant = "altgr-intl";
            };
          };
          monitors = {
            work_middle_middle_main = rec {
              mode = "3840x2160";
              model = "HP Z32";
              name = "${vendor} ${model} ${serial}";
              output = name;
              position = "-1280,0";
              refresh = "60";
              scale = "1";
              serial = "CN41212T55";
              vendor = "HP Inc.";
              workspace = "1:一";
            };
            work_middle_middle_side = rec {
              mode = "3840x2160";
              model = "HP 732pk";
              name = "${vendor} ${model} ${serial}";
              output = name;
              position = "-3440,-1050";
              refresh = "60";
              scale = "1";
              serial = "CNC4080YL5";
              transform = "270";
              vendor = "HP Inc.";
              workspace = "12:S";
            };
            work_seminary = rec {
              mode = "1280x720";
              model = "Transmitter";
              name = "${vendor} ${model} ${serial}";
              output = name;
              position = "10000,10000"; # i.e. this screen is inaccessible by moving the mouse
              scale = "1";
              serial = "QUATTRO201811";
              vendor = "Applied Creative Technology";
              workspace = "14:T";
            };
          };
        };
        services = {

          kanshi.settings = [
            {
              # seminary room
              output = confLib.mkKanshiOutput monitors.work_seminary { };
            }
            {
              # work side screen
              output = confLib.mkKanshiOutput monitors.work_middle_middle_side { };
            }
            {
              # work main screen
              output = confLib.mkKanshiOutput monitors.work_middle_middle_main { };
            }
            {
              profile = {
                exec = [
                  "${pkgs.swaybg}/bin/swaybg --output '${config.swarselsystems.sharescreen}' --image ${config.swarselsystems.wallpaper} --mode ${config.stylix.imageScalingMode}"
                  "${pkgs.swaybg}/bin/swaybg --output '${monitors.work_middle_middle_main.name}' --image ${self}/files/wallpaper/landscape/botanicswp.png --mode ${config.stylix.imageScalingMode}"
                  "${pkgs.swaybg}/bin/swaybg --output '${monitors.work_middle_middle_side.name}' --image ${self}/files/wallpaper/portrait/op6wp.png --mode ${config.stylix.imageScalingMode}"
                ];
                name = "lidopen";
                outputs = [
                  {
                    criteria = config.swarselsystems.sharescreen;
                    position = "2560,0";
                    scale = 1.5;
                    status = "enable";
                  }
                  (confLib.mkKanshiOutput monitors.work_middle_middle_side { })
                  (confLib.mkKanshiOutput monitors.work_middle_middle_main { })
                ];
              };
            }
            {
              profile =
                let
                  monitor = monitors.work_seminary;
                in
                {
                  exec = [
                    "${pkgs.swaybg}/bin/swaybg --output '${config.swarselsystems.sharescreen}' --image ${config.swarselsystems.wallpaper} --mode ${config.stylix.imageScalingMode}"
                    "${pkgs.swaybg}/bin/swaybg --output '${monitor.name}' --image ${self}/files/wallpaper/services/navidrome.png --mode ${config.stylix.imageScalingMode}"
                    "${pkgs.kanshare}/bin/kanshare ${config.swarselsystems.sharescreen} '${monitor.name}'"
                  ];
                  name = "lidopen";
                  outputs = [
                    {
                      criteria = config.swarselsystems.sharescreen;
                      position = "2560,0";
                      scale = 1.7;
                      status = "enable";
                    }
                    (confLib.mkKanshiOutput monitor { })
                  ];
                };
            }
            {
              profile = {
                exec = [
                  "${pkgs.swaybg}/bin/swaybg --output '${monitors.work_middle_middle_main.name}' --image ${self}/files/wallpaper/landscape/botanicswp.png --mode ${config.stylix.imageScalingMode}"
                  "${pkgs.swaybg}/bin/swaybg --output '${monitors.work_middle_middle_side.name}' --image ${self}/files/wallpaper/portrait/op6wp.png --mode ${config.stylix.imageScalingMode}"
                ];
                name = "lidclosed";
                outputs = [
                  {
                    criteria = config.swarselsystems.sharescreen;
                    status = "disable";
                  }
                  (confLib.mkKanshiOutput monitors.work_middle_middle_side { })
                  (confLib.mkKanshiOutput monitors.work_middle_middle_main { })
                ];
              };
            }
            {
              profile =
                let
                  monitor = monitors.work_seminary;
                in
                {
                  exec = [
                    "${pkgs.swaybg}/bin/swaybg --output '${monitor.name}' --image ${self}/files/wallpaper/services/navidrome.png --mode ${config.stylix.imageScalingMode}"
                  ];
                  name = "lidclosed";
                  outputs = [
                    {
                      criteria = config.swarselsystems.sharescreen;
                      status = "disable";
                    }
                    (confLib.mkKanshiOutput monitor { })
                  ];
                };
            }
          ];
          shikane.settings =
            let
              workRight = confLib.mkShikaneOutput monitors.work_middle_middle_main { };
              workLeft = confLib.mkShikaneOutput monitors.work_middle_middle_side { };
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
                    workRight
                    workLeft
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
                    workRight
                    workLeft
                  ];
                }

              ];
            };
        };
        stylix.targets.firefox.profileNames =
          let
            inherit (confLib.getConfig.repo.secrets.work) user1 user2 user3;
          in
          lib.mkIf (!config.programs.glide-browser.enable) [
            "${user1}"
            "${user2}"
            "${user3}"
          ];
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
            config.keybindings =
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
}
