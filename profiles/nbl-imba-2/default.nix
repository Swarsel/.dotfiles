{ inputs, outputs, config, pkgs, lib, ... }:
{

  imports = [
    inputs.nixos-hardware.nixosModules.framework-16-7040-amd

    ./hardware-configuration.nix
    ./disk-config.nix

    ../optional/nixos/steam.nix
    # ../optional/nixos/virtualbox.nix
    ../optional/nixos/autologin.nix
    ../optional/nixos/nswitch-rcm.nix
    ../optional/nixos/work.nix

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users.swarsel.imports = outputs.mixedModules ++ [
        ../optional/home/gaming.nix
        ../optional/home/work.nix
      ] ++ (builtins.attrValues outputs.homeManagerModules);
    }
  ] ++ (builtins.attrValues outputs.nixosModules);


  nixpkgs = {
    inherit (outputs) overlays;
    config = {
      allowUnfree = true;
    };
  };

  networking.networkmanager.wifi.scanRandMacAddress = false;

  boot = {
    loader.systemd-boot.enable = lib.mkForce false;
    loader.efi.canTouchEfiVariables = true;
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    supportedFilesystems = [ "btrfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "resume_offset=533760"
    ];
    resumeDevice = "/dev/disk/by-label/nixos";
  };


  networking = {
    hostName = "nbl-imba-2";
    fqdn = "nbl-imba-2.imp.univie.ac.at";
    firewall.enable = true;
  };


  services = {
    fwupd.enable = true;
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8156", ATTR{power/autosuspend}="20"
    '';
  };

  swarselsystems = {
    wallpaper = ../../wallpaper/lenovowp.png;
    hasBluetooth = true;
    hasFingerprint = true;
    impermanence = false;
    isBtrfs = true;
  };

  home-manager.users.swarsel.swarselsystems = {
    isLaptop = true;
    isNixos = true;
    isBtrfs = true;
    # temperatureHwmon = {
    #   isAbsolutePath = true;
    #   path = "/sys/devices/platform/thinkpad_hwmon/hwmon/";
    #   input-filename = "temp1_input";
    # };
    #  ------   -----
    # | DP-4 | |eDP-1|
    #  ------   -----
    startup = [
      { command = "nextcloud --background"; }
      { command = "vesktop --start-minimized --enable-speech-dispatcher --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime"; }
      { command = "element-desktop --hidden  --enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu-driver-bug-workarounds"; }
      { command = "ANKI_WAYLAND=1 anki"; }
      { command = "OBSIDIAN_USE_WAYLAND=1 obsidian"; }
      { command = "nm-applet"; }
      { command = "teams-for-linux"; }
      { command = "1password"; }
    ];
    monitors = {
      main = {
        name = "BOE 0x0BC9 Unknown";
        mode = "2560x1600"; # TEMPLATE
        scale = "1";
        position = "2560,0";
        workspace = "15:L";
        output = "eDP-2";
      };
      homedesktop = {
        name = "Philips Consumer Electronics Company PHL BDM3270 AU11806002320";
        mode = "2560x1440";
        scale = "1";
        position = "0,0";
        workspace = "1:一";
        output = "DP-11";
      };
      work_back_middle = {
        name = "LG Electronics LG Ultra HD 0x000305A6";
        mode = "2560x1440";
        scale = "1";
        position = "5120,0";
        workspace = "1:一";
        output = "DP-10";
      };
      work_front_left = {
        name = "LG Electronics LG Ultra HD 0x0007AB45";
        mode = "3840x2160";
        scale = "1";
        position = "5120,0";
        workspace = "1:一";
        output = "DP-7";
      };
      work_back_right = {
        name = "HP Inc. HP Z32 CN41212T55";
        mode = "3840x2160";
        scale = "1";
        position = "5120,0";
        workspace = "1:一";
        output = "DP-3";
      };
      work_middle_middle_main = {
        name = "HP Inc. HP 732pk CNC4080YL5";
        mode = "3840x2160";
        scale = "1";
        position = "-1280,0";
        workspace = "1:一";
        output = "DP-8";
      };
      work_middle_middle_side = {
        name = "Hewlett Packard HP Z24i CN44250RDT";
        mode = "1920x1200";
        transform = "270";
        scale = "1";
        position = "-2480,0";
        workspace = "12:S";
        output = "DP-9";
      };
      work_seminary = {
        name = "Applied Creative Technology Transmitter QUATTRO201811";
        mode = "1280x720";
        scale = "1";
        position = "10000,10000";
        workspace = "12:S";
        output = "DP-4";
      };
    };
    inputs = {
      "12972:18:Framework_Laptop_16_Keyboard_Module_-_ANSI_Keyboard" = {
        xkb_layout = "us";
        xkb_variant = "altgr-intl";
      };
      "1133:45081:MX_Master_2S_Keyboard" = {
        xkb_layout = "us";
        xkb_variant = "altgr-intl";
      };
      "2362:628:PIXA3854:00_093A:0274_Touchpad" = {
        dwt = "enabled";
        tap = "enabled";
        natural_scroll = "enabled";
        middle_emulation = "enabled";
      };
      "1133:50504:Logitech_USB_Receiver" = {
        xkb_layout = "us";
        xkb_variant = "altgr-intl";
      };
      "1133:45944:MX_KEYS_S" = {
        xkb_layout = "us";
        xkb_variant = "altgr-intl";
      };
    };
    keybindings = {
      "Mod4+Ctrl+p" = "exec wl-mirror eDP-2";
    };
  };
}
