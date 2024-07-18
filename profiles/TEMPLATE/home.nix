{
  config,
  pkgs,
  ...
}: {
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableExtraSocket = true;
    pinentryPackage = pkgs.pinentry.gtk2;
    defaultCacheTtl = 600;
    maxCacheTtl = 7200;
    extraConfig = ''
      allow-loopback-pinentry
      allow-emacs-pinentry
    '';
  };

  home = {
    username = "TEMPLATE";
    homeDirectory = "/home/TEMPLATE";
    stateVersion = "23.05"; # TEMPLATE -- Please read the comment before changing.
    keyboard.layout = "us"; # TEMPLATE
    home.packages = with pkgs; [
      # ---------------------------------------------------------------
      # if schildichat works on this machine, use it, otherwise go for element
      # element-desktop
      # ---------------------------------------------------------------
    ];
  };
  # update path if the sops private key is stored somewhere else
  sops.age.sshKeyPaths = ["${config.home.homeDirectory}/.ssh/sops"];

  # waybar config - TEMPLATE - update for cores and temp
  programs.waybar.settings.mainBar = {
    #cpu.format = "{icon0} {icon1} {icon2} {icon3}";
    cpu.format = "{icon0} {icon1} {icon2} {icon3} {icon4} {icon5} {icon6} {icon7}";
    temperature.hwmon-path = "/sys/devices/platform/coretemp.0/hwmon/hwmon1/temp3_input";
  };

  # -----------------------------------------------------------------
  # is this machine always connected to power? If yes, use this block:
  #
  # programs.waybar.settings.mainBar."custom/pseudobat"= {
  #   format= "";
  #   on-click-right= "wlogout -p layer-shell";
  # };
  # programs.waybar.settings.mainBar.modules-right = ["custom/outer-left-arrow-dark"
  #                                                   "mpris"
  #                                                   "custom/left-arrow-light"
  #                                                   "network"
  #                                                   "custom/left-arrow-dark"
  #                                                   "pulseaudio"
  #                                                   "custom/left-arrow-light"
  #                                                   "custom/pseudobat"
  #                                                   "battery"
  #                                                   "custom/left-arrow-dark"
  #                                                   "group/hardware"
  #                                                   "custom/left-arrow-light"
  #                                                   "clock#2"
  #                                                   "custom/left-arrow-dark"
  #                                                   "clock#1"
  #                                                  ];
  #
  # -----------------------------------------------------------------

  # -----------------------------------------------------------------
  # if not always connected to power (laptop), use this (default):

  programs.waybar.settings.mainBar.modules-right = [
    "custom/outer-left-arrow-dark"
    "mpris"
    "custom/left-arrow-light"
    "network"
    "custom/left-arrow-dark"
    "pulseaudio"
    "custom/left-arrow-light"
    "custom/pseudobat"
    "battery"
    "custom/left-arrow-dark"
    "group/hardware"
    "custom/left-arrow-light"
    "clock#2"
    "custom/left-arrow-dark"
    "clock#1"
  ];

  # -----------------------------------------------------------------

  wayland.windowManager.sway = {
    config = rec {
      # update for actual inputs here,
      input = {
        "36125:53060:splitkb.com_Kyria_rev3" = {
          xkb_layout = "us";
          xkb_variant = "altgr-intl";
        };
        "1:1:AT_Translated_Set_2_keyboard" = {
          # TEMPLATE
          xkb_layout = "us";
          xkb_options = "grp:win_space_toggle";
          # xkb_options = "ctrl:nocaps,grp:win_space_toggle";
          xkb_variant = "altgr-intl";
        };
        "type:touchpad" = {
          dwt = "enabled";
          tap = "enabled";
          natural_scroll = "enabled";
          middle_emulation = "enabled";
        };
      };

      output = {
        DP-1 = {
          mode = "2560x1440"; # TEMPLATE
          scale = "1";
          bg = "~/.dotfiles/wallpaper/TEMPLATE.png fill";
        };
      };

      keybindings = let
        inherit (config.wayland.windowManager.sway.config) modifier;
      in {
        # TEMPLATE
        "${modifier}+w" = "exec \"bash ~/.dotfiles/scripts/checkschildi.sh\"";
        # "${modifier}+w" = "exec \"bash ~/.dotfiles/scripts/checkelement.sh\"";
      };

      startup = [
        {command = "nextcloud --background";}
        {command = "discord --start-minimized";}
        {command = "element-desktop --hidden  -enable-features=UseOzonePlatform -ozone-platform=wayland --disable-gpu-driver-bug-workarounds";}
        {command = "ANKI_WAYLAND=1 anki";}
        {command = "OBSIDIAN_USE_WAYLAND=1 obsidian";}
        {command = "nm-applet";}
      ];
    };
  };
}
