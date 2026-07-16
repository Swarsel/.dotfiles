{
  flake.modules.nixos.lowbattery = { lib, pkgs, ... }: {
    config = {
      systemd = {
        user = {
          services."battery-low" =
            let
              target = "sway-session.target";
            in
            {
              enable = true;
              description = "Timer for battery check that alerts at 10% or less";
              partOf = [ target ];
              serviceConfig = {
                ExecStart = pkgs.writeShellScript "battery-low-notification" ''
                  if (( 10 >= $(${lib.getExe pkgs.acpi} -b | head -n 1 | ${lib.getExe pkgs.ripgrep} -o "\d+%" | ${lib.getExe pkgs.ripgrep} -o "\d+") && $(${lib.getExe pkgs.acpi} -b | head -n 1 | ${lib.getExe pkgs.ripgrep} -o "\d+%" | ${lib.getExe pkgs.ripgrep} -o "\d+") > 0 ));
                  then ${lib.getExe pkgs.libnotify} --urgency=critical "low battery" "$(${lib.getExe pkgs.acpi} -b | head -n 1 | ${lib.getExe pkgs.ripgrep} -o "\d+%")";
                  fi;
                '';
                Type = "simple";
              };
              wantedBy = [ target ];
            };
          timers."battery-low" = {
            timerConfig = {
              # Every Minute
              OnCalendar = "*-*-* *:*:00";
              Unit = "battery-low.service";
            };
            wantedBy = [ "timers.target" ];
          };
        };
      };
    };
  };
}
