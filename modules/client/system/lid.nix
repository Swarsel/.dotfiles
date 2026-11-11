{
  flake.modules.nixos.lid.config.services = {
    acpid = {
      enable = true;
      handlers = {
        lidClosed = {
          action = ''
            if grep -Fxq disabled /sys/class/backlight/amdgpu_bl1/device/enabled; then
              systemctl stop fprintd
              ln -s /dev/null /run/systemd/transient/fprintd.service
              systemctl daemon-reload
            fi
          '';
          event = "button/lid \\w+ close";
        };
        lidOpen = {
          action = ''
            if ! systemctl is-active --quiet fprintd; then
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
}
