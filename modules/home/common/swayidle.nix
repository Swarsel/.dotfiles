{ lib, config, pkgs, ... }:
let
  moduleName = "swayidle";
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "enable ${moduleName} and settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    services.${moduleName} =
      let
        brightnessctl = "${lib.getExe pkgs.brightnessctl}";
        swaylock = "${lib.getExe pkgs.swaylock-effects}";
        suspend = "${pkgs.systemd}/bin/systemctl suspend";
      in
      {
        enable = true;
        systemdTarget = config.wayland.systemd.target;
        extraArgs = [ "-w" ];
        timeouts = [
          { timeout = 60; command = "${brightnessctl} -s; ${brightnessctl} set 80%-"; resumeCommand = "${brightnessctl} -r"; }
          # { timeout = 300; command =  "${lib.getExe pkgs.swaylock-effects} -f --screenshots --clock --effect-blur 7x5 --effect-vignette 0.5:0.5 --fade-in 0.2"; }
          { timeout = 300; command = "${swaylock} -f"; }
          # { timeout = 600; command = ''${pkgs.sway}/bin/swaymsg "output * dpms off"; resumeCommand = "${pkgs.sway}/bin/swaymsg output * dpms on'';  }
          { timeout = 600; command = "${suspend}"; }
        ];
        events = {
          # { event = "before-sleep"; command = "${lib.getExe pkgs.swaylock-effects} -f --screenshots --clock --effect-blur 7x5 --effect-vignette 0.5:0.5 --fade-in 0.2"; }
          # { event = "after-resume"; command = "${swaylock} -f "; }
          before-sleep = "${swaylock} -f ";
          lock = "${swaylock} -f ";
        };
      };
  };

}
