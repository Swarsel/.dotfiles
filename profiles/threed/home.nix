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
    keyboard.layout = "us";
    packages = with pkgs; [
    ];
  };

  sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/sops" ];

  programs.waybar.settings.mainBar = {
    cpu.format = "{icon0} {icon1} {icon2} {icon3}";
    temperature.hwmon-path = "/sys/devices/platform/coretemp.0/hwmon/hwmon1/temp3_input";
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
      input = {
        "*" = {
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
        eDP-1 = {
          mode = "2160x1440@59.955Hz";
          scale = "1";
          bg = "~/.dotfiles/wallpaper/surfacewp.png fill";
        };
      };

      keybindings = let
        modifier = config.wayland.windowManager.sway.config.modifier;
      in {
        "${modifier}+F2"  = "exec brightnessctl set +5%";
        "${modifier}+F1"= "exec brightnessctl set 5%-";
        "${modifier}+n" = "exec sway output eDP-1 transform normal, splith";
        "${modifier}+Ctrl+p" = "exec wl-mirror eDP-1";
        "${modifier}+t" = "exec sway output eDP-1 transform 90, splitv";
        "${modifier}+XF86AudioLowerVolume" = "exec grim -g \"$(slurp)\" -t png - | wl-copy -t image/png";
        "${modifier}+XF86AudioRaiseVolume" = "exec grim -g \"$(slurp)\" -t png - | wl-copy -t image/png";
        "${modifier}+w" = "exec \"bash ~/.dotfiles/scripts/checkschildi.sh\"";
      };

      startup = [
        
        { command = "nextcloud --background";}
        { command = "discord --start-minimized";}
        { command = "element-desktop --hidden  -enable-features=UseOzonePlatform -ozone-platform=wayland --disable-gpu-driver-bug-workarounds";}
        { command = "ANKI_WAYLAND=1 anki";}
        { command = "OBSIDIAN_USE_WAYLAND=1 obsidian";}
        { command = "nm-applet";}
        
      ];

      keycodebindings = {
        "124" = "exec systemctl suspend";
      };
    };

    extraConfig = "
    exec swaymsg input 7062:6917:NTRG0001:01_1B96:1B05 map_to_output eDP-1
    exec swaymsg input 7062:6917:NTRG0001:01_1B96:1B05_Stylus map_to_output eDP-1
    ";
  };
}
