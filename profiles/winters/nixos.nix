{ pkgs, ... }:

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
    greetd.settings.initial_session.user = "swarsel";
  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxPackages_latest;
  };

  networking = {
    hostName = "winters"; # Define your hostname.
    nftables.enable = true;
    enableIPv6 = true;
    firewall.checkReversePath = "strict";
    firewall = {
      enable = true;
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ ];
      allowedTCPPortRanges = [
      ];
      allowedUDPPortRanges = [
      ];
    };
  };

  virtualisation.virtualbox = {
    host = {
      enable = true;
      enableExtensionPack = true;
    };
    # leaving this here for future notice. setting guest.enable = true will make 'restarting sysinit-reactivation.target' take till timeout on nixos-rebuild switch
    guest = {
      enable = false;
    };
  };

  stylix.image = ../../wallpaper/lenovowp.png;

  stylix = {
    enable = true;
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
        package = pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; };
        name = "FiraCode Nerd Font Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
  };


  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
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

  services.power-profiles-daemon.enable = true;

  users.users.swarsel = {
    isNormalUser = true;
    description = "Leon S";
    extraGroups = [ "networkmanager" "wheel" "lp" "audio" "video" "vboxusers" "scanner" ];
    packages = with pkgs; [ ];
  };

  environment.systemPackages = with pkgs; [
    sbctl
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
