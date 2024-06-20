{ config, lib, pkgs, inputs, ... }:

{

  # 
  # imports =
  #   [
  #     ./hardware-configuration.nix
  #   ];
  # 
  imports =
    [
      ./hardware-configuration.nix
    ];

  services = {
    getty.autologinUser = "swarsel";
    greetd.settings.initial_session.user="swarsel";
  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    # kernelPackages = pkgs.linuxPackages_latest;
  };

  networking = {
    hostName = "fourside"; # Define your hostname.
    nftables.enable = true;
    enableIPv6 = false;
    firewall.checkReversePath = false;
    firewall = {
      enable = true;
      allowedUDPPorts = [ 4380 27036 14242 34197 51820 ]; # 34197: factorio; 4380 27036 14242: barotrauma; 51820: wireguard
      allowedTCPPortRanges = [
        {from = 27015; to = 27030;} # barotrauma
        {from = 27036; to = 27037;} # barotrauma
      ];
      allowedUDPPortRanges = [
        {from = 27000; to = 27031;} # barotrauma
        {from = 58962; to = 58964;} # barotrauma
      ];
    };
  };

  virtualisation.virtualbox = {
    host = {
    enable = true;
    enableExtensionPack = true;
    };
    guest = {
      enable = true;
      };
    };

  stylix.image = ../../wallpaper/lenovowp.png;
  
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
  
  
  

  hardware = {
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [
          vulkan-loader
          vulkan-validation-layers
          vulkan-extension-layer
        ];
      };
      bluetooth.enable = true;
    };

  programs.steam = {
    enable = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
  };

    # Configure keymap in X11 (only used for login)

  services.thinkfan = {
    enable = false;
  };
  services.power-profiles-daemon.enable = true;

  users.users.swarsel = {
    isNormalUser = true;
    description = "Leon S";
    extraGroups = [ "networkmanager" "wheel" "lp" "audio" "video" "vboxusers" "scanner" ];
    packages = with pkgs; [];
  };

  environment.systemPackages = with pkgs; [
      # gog games installing
      heroic
      # minecraft
      temurin-bin-17
      (prismlauncher.override {
        glfw = pkgs.glfw-wayland-minecraft;
      })
  ];

  system.stateVersion = "23.05";


}
