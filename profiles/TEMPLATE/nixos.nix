{ pkgs, ... }:

{


  imports =
    [
      ./hardware-configuration.nix
    ];


  services = {
    getty.autologinUser = "TEMPLATE";
    greetd.settings.initial_session.user = "TEMPLATE";
  };

  # Bootloader
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda"; # TEMPLATE - if only one disk, this will work
    useOSProber = true;
  };

  # --------------------------------------
  # you might need a configuration like this instead:
  # Bootloader
  # boot = {
  #   kernelPackages = pkgs.linuxPackages_latest;
  #   loader.grub = {
  #     enable = true;
  #     devices = ["nodev" ];
  #     useOSProber = true;
  #   };
  # };
  # --------------------------------------

  networking.hostName = "TEMPLATE"; # Define your hostname.

  stylix.image = ../../wallpaper/TEMPLATEwp.png;

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


  # Configure keymap in X11 (only used for login)
  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
  };

  users.users.TEMPLATE = {
    isNormalUser = true;
    description = "TEMPLATE";
    extraGroups = [ "networkmanager" "wheel" "lp" "audio" "video" ];
    packages = with pkgs; [ ];
  };

  environment.systemPackages = with pkgs; [
  ];

  system.stateVersion = "23.05"; # TEMPLATE - but probably no need to change

}
