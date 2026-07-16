{
  flake.modules.nixos.lid = {
    config = {
      services = {
        acpid = {
          enable = true;
          handlers = {
            lidClosed = {
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
              event = "button/lid \\w+ close";
            };
            lidOpen = {
              action = ''
                if ! $(systemctl is-active --quiet fprintd); then
                  echo "Lid open. Enabling fprintd."
                  rm -f /run/systemd/transient/fprintd.service
                  systemctl daemon-reload
                  systemctl start fprintd
                fi
              '';
              event = "button/lid \\w+ open";
            };
          };
        };
        logind.settings.Login = {
          HandleLidSwitch = "suspend";
          HandleLidSwitchDocked = "ignore";
        };
      };
    };
  };
}
