{ self, inputs, lib, primaryUser, ... }:
let
  secretsDirectory = builtins.toString inputs.nix-secrets;
  sharedOptions = {
    isBtrfs = true;
    isLinux = true;
    sharescreen = "eDP-2";
    profiles = {
      personal = true;
      work = true;
    };
  };
in
{

  imports = [
    inputs.nixos-hardware.nixosModules.framework-16-7040-amd
    inputs.fw-fanctrl.nixosModules.default

    ./disk-config.nix
    ./hardware-configuration.nix

  ];



  networking.networkmanager.wifi.scanRandMacAddress = false;

  boot = {
    supportedFilesystems = [ "btrfs" ];
    # kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    kernelParams = [
      "resume_offset=533760"
    ];
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  hardware = {
    enableAllFirmware = true;
    cpu.amd.updateMicrocode = true;
    amdgpu = {
      opencl.enable = true;
      amdvlk = {
        enable = true;
        support32Bit.enable = true;
      };
    };
  };

  programs.fw-fanctrl = {
    enable = true;
    config = {
      defaultStrategy = "lazy";
    };
  };

  networking = {
    hostName = lib.swarselsystems.getSecret "${secretsDirectory}/work/worklaptop-hostname";
    fqdn = lib.swarselsystems.getSecret "${secretsDirectory}/work/worklaptop-fqdn";
    firewall.enable = true;
  };


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

  swarselsystems = lib.recursiveUpdate
    {
      wallpaper = self + /wallpaper/lenovowp.png;
      hasBluetooth = true;
      hasFingerprint = true;
      isImpermanence = false;
      isSecureBoot = true;
      isCrypted = true;
    }
    sharedOptions;

  home-manager.users."${primaryUser}" = {
    home.stateVersion = lib.mkForce "23.05";
    swarselsystems = lib.recursiveUpdate
      {
        isLaptop = true;
        isNixos = true;
        isSecondaryGpu = true;
        SecondaryGpuCard = "pci-0000_03_00_0";
        cpuCount = 16;
        temperatureHwmon = {
          isAbsolutePath = true;
          path = "/sys/devices/virtual/thermal/thermal_zone0/";
          input-filename = "temp4_input";
        };
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
            workspace = "14:T";
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
          # "2362:628:PIXA3854:00_093A:0274_Touchpad" = {
          #   dwt = "enabled";
          #   tap = "enabled";
          #   natural_scroll = "enabled";
          #   middle_emulation = "enabled";
          #   drag_lock = "disabled";
          # };
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
  };
}
