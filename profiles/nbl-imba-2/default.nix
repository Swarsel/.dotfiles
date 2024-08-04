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

  hardware.graphics.extraPackages = with pkgs; [
    vulkan-loader
    vulkan-validation-layers
    vulkan-extension-layer
  ];

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
    initialSetup = true;
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
    monitors = {
      main = {
        name = "BOE 0x0BC9 Unknown";
        mode = "2560x1600"; # TEMPLATE
        scale = "1";
        position = "2560,0";
        workspace = "2:二";
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
      workdesktop = {
        name = "LG Electronics LG Ultra HD 0x000305A6";
        mode = "2560x1440";
        scale = "1";
        position = "0,0";
        workspace = "1:一";
        output = "DP-10";
      };
    };
    inputs = {
      "12972:18:Framework_Laptop_16_Keyboard_Module_-_ANSI_Keyboard" = {
        xkb_layout = "us";
        xkb_options = "grp:win_space_toggle";
        xkb_variant = "altgr-intl";
      };
      "2362:628:PIXA3854:00_093A:0274_Touchpad" = {
        dwt = "enabled";
        tap = "enabled";
        natural_scroll = "enabled";
        middle_emulation = "enabled";
      };
    };
    keybindings = { };
  };
}
