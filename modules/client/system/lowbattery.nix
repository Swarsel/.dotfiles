{
  flake.modules.nixos.lowbattery = { lib, pkgs, ... }: {
    config.systemd.user = {
      services.battery-low =
        let
          target = "sway-session.target";
        in
        {
          enable = true;
          description = "Timer for battery check that alerts at 10% or less";
          partOf = [ target ];
          serviceConfig = {
            ExecStart = lib.getExe (
              pkgs.writeShellApplication {
                name = "battery-low-notification";
                runtimeInputs = [
                  pkgs.acpi
                  pkgs.coreutils
                  pkgs.libnotify
                  pkgs.ripgrep
                ];
                text = ''
                  level=$(acpi -b | head -n 1 | rg -o "\d+%" | rg -o "\d+") || exit 0
                  if (( level <= 10 && level > 0 )); then
                    notify-send --urgency=critical "low battery" "$level%"
                  fi
                '';
              }
            );
            Type = "simple";
          };
          wantedBy = [ target ];
        };
      timers.battery-low = {
        timerConfig = {
          # Every Minute
          OnCalendar = "*-*-* *:*:00";
          Unit = "battery-low.service";
        };
        wantedBy = [ "timers.target" ];
      };
    };
  };
}
