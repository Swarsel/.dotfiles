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
        pkgs,
        confLib,
        withHomeManager,
        ...
      }:
      {
        config = {
          users.persistentIds.fwupd-refresh = confLib.mkIds 959;
          boot.extraModprobeConfig = ''
            options snd-hda-intel patch=alc295-framework-jack.fw,alc295-framework-jack.fw,alc295-framework-jack.fw
          '';
          hardware.firmware = [
            (pkgs.writeTextFile {
              name = "alc295-framework-jack";
              destination = "/lib/firmware/alc295-framework-jack.fw";
              text = ''
                [codec]
                0x10ec0295 0xf1110005 0

                [model]
                headset-mode-no-hp-mic

                [pincfg]
                0x19 0x02a1112c
                0x21 0x02211020
              '';
            })
          ];
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
        }
        // lib.optionalAttrs withHomeManager {
          home-manager.users."${config.swarselsystems.mainUser}".imports = [
            fmods.homeManager.framework
          ];
        };
      };
  };
}
