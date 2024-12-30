{ self, inputs, outputs, pkgs, lib, ... }:
let
  profilesPath = "${self}/profiles";
  sharedOptions = {
    isBtrfs = true;
  };
in
{

  imports = outputs.nixModules ++ [
    inputs.nixos-hardware.nixosModules.framework-16-7040-amd
    inputs.fw-fanctrl.nixosModules.default

    ./hardware-configuration.nix
    ./disk-config.nix

    "${profilesPath}/optional/nixos/virtualbox.nix"
    # "${profilesPath}/optional/nixos/vmware.nix"
    "${profilesPath}/optional/nixos/autologin.nix"
    "${profilesPath}/optional/nixos/nswitch-rcm.nix"
    "${profilesPath}/optional/nixos/gaming.nix"
    "${profilesPath}/optional/nixos/work.nix"

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users.swarsel.imports = outputs.mixedModules ++ [
        "${profilesPath}/optional/home/gaming.nix"
        "${profilesPath}/optional/home/work.nix"
      ] ++ (builtins.attrValues outputs.homeManagerModules);
    }
  ] ++ (builtins.attrValues outputs.nixosModules);



  networking.networkmanager.wifi.scanRandMacAddress = false;

  boot = {
    supportedFilesystems = [ "btrfs" ];
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    kernelParams = [
      "resume_offset=533760"
    ];
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  hardware = {
    amdgpu = {
      opencl.enable = true;
      amdvlk = {
        enable = true;
        support32Bit.enable = true;
      };
    };
  };

  programs.fw-fanctrl.enable = true;

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

  swarselsystems = lib.recursiveUpdate
    {
      wallpaper = self + /wallpaper/lenovowp.png;
      hasBluetooth = true;
      hasFingerprint = true;
      isImpermanence = false;
      isSecureBoot = true;
      isCrypted = true;
      isLinux = true;
    }
    sharedOptions;

  home-manager.users.swarsel.swarselsystems = lib.recursiveUpdate
    {
      isLaptop = true;
      isNixos = true;
      flakePath = "/home/swarsel/.dotfiles";
      cpuCount = 16;
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
        { command = "feishin"; }
      ];
      sharescreen = "eDP-2";
      lowResolution = "1280x800";
      highResolution = "2560x1600";
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
          workspace = "11:M";
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
          position = "10000,10000"; # i.e. this screen is inaccessible by moving the mouse
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
        "Mod4+Ctrl+Shift+p" = "exec screenshare";
      };
      shellAliases = {
        ans2-15_3-9 = ". ~/.venvs/ansible39_2_15_0/bin/activate";
        ans3-9 = ". ~/.venvs/ansible39/bin/activate";
        ans = ". ~/.venvs/ansible/bin/activate";
        ans2-15 = ". ~/.venvs/ansible2.15.0/bin/activate";
      };
    }
    sharedOptions;
}
