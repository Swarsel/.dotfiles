{ pkgs, lib, config, ... }:
{
  options.swarselmodules.lowBattery = lib.mkEnableOption "low battery notification config";
  config = lib.mkIf config.swarselmodules.lowBattery {
    systemd.user.services."battery-low" = {
      enable = true;
      description = "Timer for battery check that alerts at 10% or less";
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "battery-low-notification"
          ''
            if (( 10 >= $(${lib.getExe pkgs.acpi} -b | head -n 1 | ${lib.getExe pkgs.ripgrep} -o "\d+%" | ${lib.getExe pkgs.ripgrep} -o "\d+") && $(${lib.getExe pkgs.acpi} -b | head -n 1 | ${lib.getExe pkgs.ripgrep} -o "\d+%" | ${lib.getExe pkgs.ripgrep} -o "\d+") > 0 ));
            then ${lib.getExe pkgs.libnotify} --urgency=critical "low battery" "$(${lib.getExe pkgs.acpi} -b | head -n 1 | ${lib.getExe pkgs.ripgrep} -o "\d+%")";
            fi;
          '';
      };
    };
    systemd.user.timers."battery-low" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        # Every Minute
        OnCalendar = "*-*-* *:*:00";
        Unit = "battery-low.service";
      };
    };
  };
}
