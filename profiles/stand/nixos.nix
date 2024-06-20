{ config, lib, pkgs, inputs, ... }:

{

  
  imports =
    [
      ./hardware-configuration.nix
    ];
  

  services = {
    getty.autologinUser = "homelen";
    greetd.settings.initial_session.user="homelen";
  };

  stylix.image = ../../wallpaper/standwp.png;
  
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
  
  
  

  # Bootloader.
  boot.loader.grub = {
    enable = true;
    devices = ["nodev" ];
    useOSProber = true;
  };

  # boot.kernelPackages = pkgs.linuxPackages_latest;
  networking = {
    hostName = "stand"; # Define your hostname.
    enableIPv6 = false;
    firewall.enable = false;
  # networkmanager.enable = true;
  };

  hardware = {
    bluetooth.enable = true;
  };

  users.users.homelen = {
    isNormalUser = true;
    description = "Leon S";
    extraGroups = [ "networkmanager" "wheel" "lp" "audio" "video" ];
    packages = with pkgs; [];
  };

  environment.systemPackages = with pkgs; [
  ];

  system.stateVersion = "23.05"; # Did you read the comment? Dont change this basically

}
