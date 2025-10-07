{ lib, config, ... }:
{
  options.swarselmodules.optional.framework = lib.mkEnableOption "optional framework machine settings";
  config = lib.mkIf config.swarselmodules.optional.framework {
    services = {
      fwupd = {
        enable = true;
        # framework also uses lvfs-testing, but I do not want to use it
        extraRemotes = [ "lvfs" ];
      };
      udev.extraRules = ''
        # disable Wakeup on Framework Laptop 16 Keyboard (ANSI)
        ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0012", ATTR{power/wakeup}="disabled"
        # disable Wakeup on Framework Laptop 16 Numpad Module
        ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0014", ATTR{power/wakeup}="disabled"
        # disable Wakeup on Framework Laptop 16 Trackpad
        ACTION=="add", SUBSYSTEM=="i2c", DRIVERS=="i2c_hid_acpi", ATTRS{name}=="PIXA3854:00", ATTR{power/wakeup}="disabled"
      '';
    };
    hardware.fw-fanctrl = {
      enable = true;
      config = {
        defaultStrategy = "lazy";
      };
    };
  };
}
