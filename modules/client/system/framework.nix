{ config, ... }:
let
  fmods = config.flake.modules;
in
{
  flake.modules = {
    homeManager.framework.config.swarselsystems.inputs."12972:18:Framework_Laptop_16_Keyboard_Module_-_ANSI_Keyboard" =
      {
        xkb_layout = "us";
        xkb_variant = "altgr-intl";
      };
    nixos.framework =
      {
        config,
        lib,
        confLib,
        withHomeManager,
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
              ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0012", ATTR{power/wakeup}="disabled"
              # disable Wakeup on Framework Laptop 16 Numpad Module
              ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0014", ATTR{power/wakeup}="disabled"
              # disable Wakeup on Framework Laptop 16 Trackpad
              ACTION=="add", SUBSYSTEM=="i2c", DRIVERS=="i2c_hid_acpi", ATTRS{name}=="PIXA3854:00", ATTR{power/wakeup}="disabled"
            '';
          };
          hardware.fw-fanctrl = {
            config.defaultStrategy = "lazy";
            enable = true;
          };
        }
        // lib.optionalAttrs withHomeManager {
          home-manager.users."${config.swarselsystems.mainUser}".imports = [
            fmods.homeManager.framework
          ];
        };
      };
  };
}
