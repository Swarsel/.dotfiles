{ inputs, outputs, config, pkgs, ... }:
{

  imports = [
    inputs.nixos-hardware.nixosModules.framework-16-7040-amd

    ./hardware-configuration.nix

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

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
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
  };

  swarselsystems = {
    wallpaper = ../../wallpaper/lenovowp.png;
    hasBluetooth = true;
    hasFingerprint = true;
    initialSetup = true;
  };

  home-manager.users.swarsel.swarselsystems = {
    isLaptop = true;
    isNixos = true;
    # temperatureHwmon = {
    #   isAbsolutePath = true;
    #   path = "/sys/devices/platform/thinkpad_hwmon/hwmon/";
    #   input-filename = "temp1_input";
    # };
    #  ------   -----
    # | DP-4 | |eDP-1|
    #  ------   -----
    # monitors = {
    #   main = {
    #     name = "California Institute of Technology 0x1407 Unknown";
    #     mode = "1920x1080"; # TEMPLATE
    #     scale = "1";
    #     position = "2560,0";
    #     workspace = "2:二";
    #     output = "eDP-1";
    #   };
    #   homedesktop = {
    #     name = "Philips Consumer Electronics Company PHL BDM3270 AU11806002320";
    #     mode = "2560x1440";
    #     scale = "1";
    #     position = "0,0";
    #     workspace = "1:一";
    #     output = "DP-4";
    #   };
    # };
    # inputs =  {
    #   "1:1:AT_Translated_Set_2_keyboard" = {
    #     xkb_layout = "us";
    #     xkb_options = "grp:win_space_toggle";
    #     xkb_variant = "altgr-intl";
    #   };
    # };
    keybindings = { };
  };
}
