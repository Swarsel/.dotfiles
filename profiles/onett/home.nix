{ config, pkgs, lib, fetchFromGitHub, ... }:

{

  
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableExtraSocket = true;
    pinentryPackage = pkgs.pinentry-gtk2;
    extraConfig = ''
    allow-emacs-pinentry
    allow-loopback-pinentry
    '';
    };
  

  home = {
    username = "swarsel";
    homeDirectory = "/home/swarsel";
    stateVersion = "23.05"; # Please read the comment before changing.
    keyboard.layout = "de";
    packages = with pkgs; [
    ];
  };

  sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/sops" ];

  # # waybar config
  programs.waybar.settings.mainBar = {
    cpu.format = "{icon0} {icon1} {icon2} {icon3} {icon4} {icon5} {icon6} {icon7}";
    temperature.hwmon-path = "/sys/devices/platform/coretemp.0/hwmon/hwmon3/temp3_input";
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
  

  services.blueman-applet.enable = true;

  wayland.windowManager.sway= {
    config = rec {
      input = {
        "1:1:AT_Translated_Set_2_keyboard" = {
          xkb_layout = "us";
          xkb_options = "grp:win_space_toggle";
          # xkb_options = "ctrl:nocaps,grp:win_space_toggle";
          xkb_variant = "altgr-intl";
        };
        "2362:33538:ipad_keyboard_Keyboard" = {
          xkb_layout = "us";
          xkb_options = "altwin:swap_lalt_lwin,ctrl:nocaps,grp:win_space_toggle";
          xkb_variant = "colemak_dh";
        };
        "36125:53060:splitkb.com_Kyria_rev3" = {
          xkb_layout = "us";
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
        eDP-1 = {
          mode = "1920x1080";
          scale = "1";
          bg = "~/.dotfiles/wallpaper/lenovowp.png fill";
          position = "1920,0";
        };
        VGA-1 = {
          mode = "1920x1080";
          scale = "1";
          bg = "~/.dotfiles/wallpaper/lenovowp.png fill";
          position = "0,0";
        };
      };

      keybindings = let
        modifier = config.wayland.windowManager.sway.config.modifier;
      in {
        "${modifier}+F2"  = "exec brightnessctl set +5%";
        "${modifier}+F1"= "exec brightnessctl set 5%-";
        "XF86MonBrightnessUp"  = "exec brightnessctl set +5%";
        "XF86MonBrightnessDown"= "exec brightnessctl set 5%-";
        "${modifier}+Ctrl+p" = "exec wl-mirror eDP-1";
        "XF86HomePage" = "exec wtype -P Escape -p Escape";
        "${modifier}+w" = "exec \"bash ~/.dotfiles/scripts/checkschildi.sh\"";
      };
      keycodebindings = {
        "94" = "exec wtype c";
        "Shift+94" = "exec wtype C";
        "Ctrl+94" = "exec wtype -M ctrl c -m ctrl";
        "Ctrl+Shift+94" = "exec wtype -M ctrl -M shift c -m ctrl -m shift";
      };

      startup = [
        
        { command = "nextcloud --background";}
        { command = "discord --start-minimized";}
        { command = "element-desktop --hidden  -enable-features=UseOzonePlatform -ozone-platform=wayland --disable-gpu-driver-bug-workarounds";}
        { command = "ANKI_WAYLAND=1 anki";}
        { command = "OBSIDIAN_USE_WAYLAND=1 obsidian";}
        { command = "nm-applet";}
        
      ];
    };

    extraConfig = "
 ";
  };
}
