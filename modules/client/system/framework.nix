{
  flake.modules.nixos.framework =
    {
      confLib,
      ...
    }:
    {
      config = {
        users.persistentIds.fwupd-refresh = confLib.mkIds 959;
        services = {
          fwupd = {
            enable = true;
            # framework also uses lvfs-testing, but I do not want to use it
            extraRemotes = [ "lvfs" ];
          };
          udev.extraRules = ''
            # disable Wakeup on Framework Laptop 16 Keyboard (ANSI)
            ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="32ac", ATTR{idProduct}=="0012", ATTR{power/wakeup}="disabled"
            # disable Wakeup on Framework Laptop 16 Numpad Module
            ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="32ac", ATTR{idProduct}=="0014", ATTR{power/wakeup}="disabled"
            # disable Wakeup on Framework Laptop 16 Trackpad
            ACTION=="add", SUBSYSTEM=="i2c", DRIVERS=="i2c_hid_acpi", ATTRS{name}=="PIXA3854:00", ATTR{power/wakeup}="disabled"
          '';
        };
        hardware.fw-fanctrl = {
          config.defaultStrategy = "lazy";
          enable = true;
        };
      };
    };
}
