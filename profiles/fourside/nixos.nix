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
      inputs.nix-gaming.nixosModules.steamCompat
      ./hardware-configuration.nix
    ];
  nix.settings = {
    substituters = ["https://nix-gaming.cachix.org"];
    trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
  };

  services = {
    getty.autologinUser = "swarsel";
    greetd.settings.initial_session.user="swarsel";
  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  networking.hostName = "fourside"; # Define your hostname.
  networking.firewall.enable = false;
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
      inputs.nix-gaming.packages.${pkgs.system}.proton-ge
    ];
  };

    # Configure keymap in X11 (only used for login)
  services.xserver = {
    layout = "us";
    xkbVariant = "altgr-intl";
  };

  users.users.swarsel = {
    isNormalUser = true;
    description = "Leon S";
    extraGroups = [ "networkmanager" "wheel" "lp" "audio" "video" ];
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
