{ config, pkgs, lib, fetchFromGitHub, ... }:

{

  
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableExtraSocket = true;
    pinentryPackage = pkgs.pinentry-gtk2;
  };
  
  home = {
    username = "swarsel";
    homeDirectory = "/home/swarsel";
    stateVersion = "23.05"; # TEMPLATE -- Please read the comment before changing.
    keyboard.layout = "us"; # TEMPLATE
    packages = with pkgs; [
    ];
  };
  sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/sops" ];

  # waybar config - TEMPLATE - update for cores and temp
  programs.waybar.settings.mainBar = {
    cpu.format = "{icon0} {icon1} {icon2} {icon3} {icon4} {icon5} {icon6} {icon7}";
    # temperature.hwmon-path = "/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon4/temp1_input";
    temperature.hwmon-path.abs = "/sys/devices/platform/thinkpad_hwmon/hwmon/";
    temperature.input-filename = "temp1_input";
  };

  
  programs.waybar.settings.mainBar.modules-right = ["custom/outer-left-arrow-dark"
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
  

  wayland.windowManager.sway= {
    config = rec {
      # update for actual inputs here,
      input = {
        "36125:53060:splitkb.com_Kyria_rev3" = {
          xkb_layout = "us";
          xkb_variant = "altgr-intl";
        };
        "1:1:AT_Translated_Set_2_keyboard" = { # TEMPLATE
          xkb_layout = "us";
          xkb_options = "grp:win_space_toggle";
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
          #bg = "~/.dotfiles/wallpaper/lenovowp.png fill";
        };
      };

      keybindings = let
        modifier = config.wayland.windowManager.sway.config.modifier;
      in {
        "${modifier}+w" = "exec \"bash ~/.dotfiles/scripts/checkelement.sh\"";
        "XF86MonBrightnessUp"  = "exec brightnessctl set +5%";
        "XF86MonBrightnessDown"= "exec brightnessctl set 5%-";
        "XF86Display" = "exec wl-mirror eDP-1";
        # these are left open to use
        # "XF86WLAN" = "exec wl-mirror eDP-1";
        # "XF86Messenger" = "exec wl-mirror eDP-1";
        # "XF86Go" = "exec wl-mirror eDP-1";
        # "XF86Favorites" = "exec wl-mirror eDP-1";
        # "XF86HomePage" = "exec wtype -P Escape -p Escape";
        # "XF86AudioLowerVolume" = "pactl set-sink-volume alsa_output.pci-0000_08_00.6.HiFi__hw_Generic_1__sink -5%";
        # "XF86AudioRaiseVolume" = "pactl set-sink-volume alsa_output.pci-0000_08_00.6.HiFi__hw_Generic_1__sink +5%  ";
        "XF86AudioMute" = "pactl set-sink-mute alsa_output.pci-0000_08_00.6.HiFi__hw_Generic_1__sink toggle";
      };

      startup = [
        
        { command = "nextcloud --background";}
        # { command = "spotify";}
        { command = "discord --start-minimized";}
        { command = "element-desktop --hidden";}
        { command = "ANKI_WAYLAND=1 anki";}
        { command = "OBSIDIAN_USE_WAYLAND=1 obsidian";}
        { command = "nm-applet";}
        # { command = "sleep 60 && syncthingtray --wait"; }
        
      ];
    };
  };
}
