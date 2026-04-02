{ lib, config, ... }:
{
  options.swarselmodules.lid = lib.mkEnableOption "lid config";
  config = lib.mkIf config.swarselmodules.lid {
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchDocked = "ignore";
    };
    services.acpid = {
      enable = true;
      handlers.lidClosed = {
        event = "button/lid \\w+ close";
        action = ''
          cat /sys/class/backlight/amdgpu_bl1/device/enabled
          if grep -Fxq disabled /sys/class/backlight/amdgpu_bl1/device/enabled
          then
            echo "Lid closed. Disabling fprintd."
            systemctl stop fprintd
            ln -s /dev/null /run/systemd/transient/fprintd.service
            systemctl daemon-reload
          fi
        '';
      };
      handlers.lidOpen = {
        event = "button/lid \\w+ open";
        action = ''
          if ! $(systemctl is-active --quiet fprintd); then
            echo "Lid open. Enabling fprintd."
            rm -f /run/systemd/transient/fprintd.service
            systemctl daemon-reload
            systemctl start fprintd
          fi
        '';
      };
    };
  };
}
