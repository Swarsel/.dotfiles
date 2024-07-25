{ inputs, outputs, config, pkgs, ... }:
{

  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen2

    ./hardware-configuration.nix

    ../optional/nixos/steam.nix
    ../optional/nixos/virtualbox.nix
    ../optional/nixos/autologin.nix
    ../optional/nixos/nswitch-rcm.nix

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users.swarsel.imports = outputs.mixedModules ++ [
        ../optional/home/gaming.nix
      ] ++ (builtins.attrValues outputs.homeManagerModules);
    }
  ] ++ (builtins.attrValues outputs.nixosModules);


  nixpkgs = {
    overlays = outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxPackages_latest;
  };


  networking = {
    hostName = "fourside";
    firewall.enable = true;
  };

  hardware.graphics.extraPackages = with pkgs; [
    vulkan-loader
    vulkan-validation-layers
    vulkan-extension-layer
  ];

  services = {
    thinkfan.enable = false;
    fwupd.enable = true;
  };

  swarselsystems = {
    wallpaper = ../../wallpaper/lenovowp.png;
    hasBluetooth = true;
    hasFingerprint = true;
    trackpoint = {
      isAvailable = true;
      device = "TPPS/2 Elan TrackPoint";
    };
  };

  home-manager.users.swarsel.swarselsystems = {
    isLaptop = true;
    isNixos = true;
    temperatureHwmon = {
      isAbsolutePath = true;
      path = "/sys/devices/platform/thinkpad_hwmon/hwmon/";
      input-filename = "temp1_input";
    };
    #  ------   -----
    # | DP-4 | |eDP-1|
    #  ------   -----
    monitors = {
      main = {
        name = "California Institute of Technology 0x1407 Unknown";
        mode = "1920x1080"; # TEMPLATE
        scale = "1";
        position = "2560,0";
        workspace = "2:二";
        output = "eDP-1";
      };
      homedesktop = {
        name = "Philips Consumer Electronics Company PHL BDM3270 AU11806002320";
        mode = "2560x1440";
        scale = "1";
        position = "0,0";
        workspace = "1:一";
        output = "DP-4";
      };
    };
    inputs = {
      "1:1:AT_Translated_Set_2_keyboard" = {
        xkb_layout = "us";
        xkb_options = "grp:win_space_toggle";
        xkb_variant = "altgr-intl";
      };
    };
    keybindings = {
      "Mod4+w" = "exec \"bash ~/.dotfiles/scripts/checkelement.sh\"";
      "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
      "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
      "XF86Display" = "exec wl-mirror eDP-1";
      # these are left open to use
      # "XF86WLAN" = "exec wl-mirror eDP-1";
      # "XF86Messenger" = "exec wl-mirror eDP-1";
      # "XF86Go" = "exec wl-mirror eDP-1";
      # "XF86Favorites" = "exec wl-mirror eDP-1";
      # "XF86HomePage" = "exec wtype -P Escape -p Escape";
      # "XF86AudioLowerVolume" = "pactl set-sink-volume alsa_output.pci-0000_08_00.6.HiFi__hw_Generic_1__sink -5%";
      # "XF86AudioRaiseVolume" = "pactl set-sink-volume alsa_output.pci-0000_08_00.6.HiFi__hw_Generic_1__sink +5%  ";
      "XF86AudioMute" = "exec pactl set-sink-mute alsa_output.pci-0000_08_00.6.HiFi__Speaker__sink toggle && exec pactl set-sink-mute alsa_output.usb-Lenovo_ThinkPad_Thunderbolt_4_Dock_USB_Audio_000000000000-00.analog-stereo toggle";
    };
  };

}
