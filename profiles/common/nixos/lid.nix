{ config, pkgs, ... }:
{
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchDocked = "ignore";
  };
  services.acpid = {
    enable = true;
    lidEventCommands =
      ''
        export PATH=$PATH:/run/current-system/sw/bin
        export WAYLAND_DISPLAY=wayland-1
        export XDG_RUNTIME_DIR=/run/user/1000
        export SWAYSOCK=$(ls /run/user/1000/sway-ipc.* | head -n 1)

        LID_STATE=$(cat /proc/acpi/button/lid/*/state | grep -q closed && echo "closed" || echo "open")
        DOCKED=$(swaymsg -t get_outputs | grep -q 'HDMI\|DP' && echo "docked" || echo "undocked")

        if [ "$LID_STATE" == "closed" ] && [ "$DOCKED" == "docked" ]; then
            swaymsg output eDP-2 disable
        else
            swaymsg output eDP-2 enable
        fi
      '';
  };
}
