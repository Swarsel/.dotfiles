{
  flake.modules.homeManager.work-desktop =
    {
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
        swarselsystems.monitors = {
          work_middle_middle_main = rec {
            columns = "3";
            mode = "5120x2160";
            model = "LG ULTRAFINE";
            name = "${vendor} ${model} ${serial}";
            output = name;
            position = "-2560,0";
            scale = "1";
            serial = "510NTEPPU036";
            vendor = "LG Electronics";
            workspace = "1:一";
          };
          work_middle_middle_side = rec {
            columns = "1";
            mode = "3840x2160";
            model = "HP 732pk";
            name = "${vendor} ${model} ${serial}";
            output = name;
            position = "-4720,-1050";
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
        services.shikane.settings =
          let
            workRight = confLib.mkShikaneOutput monitors.work_middle_middle_main { };
            workLeft = confLib.mkShikaneOutput monitors.work_middle_middle_side { };
            seminary = confLib.mkShikaneOutput monitors.work_seminary { };
            internalOn = {
              enable = true;
              match = config.swarselsystems.sharescreen;
              position = "2560,0";
              scale = 1.7;
            };
            internalOff = internalOn // {
              enable = false;
            };
            exec = [
              "${lib.getExe' pkgs.libnotify "notify-send"} shikane \"Profile $SHIKANE_PROFILE_NAME has been applied\""
            ];
          in
          {
            profile = [

              {
                inherit exec;
                name = "work-internal-on";
                output = [
                  internalOn
                  workRight
                  workLeft
                ];
              }
              {
                inherit exec;
                name = "work-internal-off";
                output = [
                  internalOff
                  workRight
                  workLeft
                ];
              }
              {
                exec = exec ++ [
                  (lib.getExe (
                    pkgs.writeShellApplication {
                      name = "nirishare";
                      runtimeInputs = [
                        pkgs.noctalia
                        pkgs.procps
                        pkgs.wl-mirror
                        pkgs.wlr-randr
                      ];
                      text = ''
                        if pgrep wl-mirror >/dev/null; then
                          exit 0
                        fi
                        target=$(wlr-randr | grep '${monitors.work_seminary.name}' | cut -d' ' -f1)
                        setsid sh -c "
                          noctalia msg notification-dnd-set on
                          wl-present mirror '${config.swarselsystems.sharescreen}' --fullscreen-output '$target'
                          noctalia msg notification-dnd-set off
                        " >/dev/null 2>&1 &
                      '';
                    }
                  ))
                ];
                name = "seminar-internal-on";
                output = [
                  internalOn
                  seminary
                ];
              }
              {
                inherit exec;
                name = "seminar-internal-off";
                output = [
                  internalOff
                  seminary
                ];
              }

            ];
          };
      };
    };
}
