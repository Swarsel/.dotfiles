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
    temurin-bin-17

    (prismlauncher.override {
      glfw = (let
        mcWaylandPatchRepo = fetchFromGitHub {
          owner = "Admicos";
          repo = "minecraft-wayland";
          rev = "370ce5b95e3ae9bc4618fb45113bc641fbb13867";
          sha256 =
            "sha256-RPRg6Gd7N8yyb305V607NTC1kUzvyKiWsh6QlfHW+JE=";
        };
        mcWaylandPatches = map (name: "${mcWaylandPatchRepo}/${name}")
          (lib.naturalSort (builtins.attrNames (lib.filterAttrs
          (name: type:
            type == "regular" && lib.hasSuffix ".patch" name)
            (builtins.readDir mcWaylandPatchRepo))));
      in glfw-wayland.overrideAttrs (previousAttrs: {
        patches = previousAttrs.patches ++ mcWaylandPatches;
      }));})
  ];

  system.stateVersion = "23.05";

}
