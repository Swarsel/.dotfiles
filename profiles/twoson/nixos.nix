{ config, lib, pkgs, inputs, ... }:

{

  
  imports =
    [
      ./hardware-configuration.nix
    ];
  

  services = {
    getty.autologinUser = "swarsel";
    greetd.settings.initial_session.user="swarsel";
  };

  # Bootloader
  # boot.loader.grub.enable = true;
  # boot.loader.grub.device = "/dev/sda"; # TEMPLATE - if only one disk, this will work
  # boot.loader.grub.useOSProber = true;

  # --------------------------------------
  # you might need a configuration like this instead:
  # Bootloader
  # boot.loader.grub.enable = true;
  # boot.loader.grub.devices = ["nodev" ];
  # boot.loader.grub.useOSProber = true;
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # --------------------------------------

  networking.hostName = "twoson"; # Define your hostname.

  stylix.image = ../../wallpaper/t14swp.png;
  
  
  stylix = {
    base16Scheme = ../../wallpaper/swarsel.yaml;
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/shapeshifter.yaml";
    polarity = "dark";
    opacity.popups = 0.5;
    cursor = {
      package = pkgs.capitaine-cursors;
      name = "capitaine-cursors";
      size = 16;
    };
    fonts = {
      sizes = {
        terminal = 10;
        applications = 11;
      };
      serif = {
        # package = (pkgs.nerdfonts.override { fonts = [ "FiraMono" "FiraCode"]; });
        package = pkgs.cantarell-fonts;
        # package = pkgs.montserrat;
        name = "Cantarell";
        # name = "FiraCode Nerd Font Propo";
        # name = "Montserrat";
      };
  
      sansSerif = {
        # package = (pkgs.nerdfonts.override { fonts = [ "FiraMono" "FiraCode"]; });
        package = pkgs.cantarell-fonts;
        # package = pkgs.montserrat;
        name = "Cantarell";
        # name = "FiraCode Nerd Font Propo";
        # name = "Montserrat";
      };
  
      monospace = {
        package = (pkgs.nerdfonts.override { fonts = [ "FiraCode"]; });
        name = "FiraCode Nerd Font Mono";
      };
  
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
  
  
  

  # Configure keymap in X11 (only used for login)
  services.xserver = {
    layout = "us";
    xkbVariant = "altgr-intl";
  };

  users.users.swarsel = {
    isNormalUser = true;
    description = "TEMPLATE";
    extraGroups = [ "networkmanager" "wheel" "lp" "audio" "video" ];
    packages = with pkgs; [];
  };

  environment.systemPackages = with pkgs; [
  ];

  system.stateVersion = "23.05"; # TEMPLATE - but probably no need to change


}
