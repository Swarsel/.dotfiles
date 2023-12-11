{ config, pkgs, lib, fetchFromGitHub, ... }:

{

  
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };
  

  home = {
    username = "homelen";
    homeDirectory = "/home/homelen";
    stateVersion = "23.05"; # Please read the comment before changing.
    keyboard.layout = "us";
    packages = with pkgs; [
    ];
  };

  sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/sops" ];

  services.blueman-applet.enable = true;

  # waybar config
  programs.waybar.settings.mainBar = {
    cpu.format = "{icon0} {icon1} {icon2} {icon3} {icon4} {icon5} {icon6} {icon7}";
    temperature.hwmon-path = "/sys/devices/platform/coretemp.0/hwmon/hwmon1/temp3_input";
  };
  
  programs.waybar.settings.mainBar."custom/pseudobat"= {
    format= "";
    on-click-right= "wlogout -p layer-shell";
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
        "36125:53060:splitkb.com_Kyria_rev3" = {
          xkb_layout = "us";
          xkb_variant = "altgr-intl";
        };
      };

      output = {
        DP-1 = {
          mode = "2560x1440";
          scale = "1";
          bg = "~/.dotfiles/wallpaper/standwp.png fill";
        };
      };

      keybindings = let
        modifier = config.wayland.windowManager.sway.config.modifier;
      in {
        "${modifier}+w" = "exec \"bash ~/.dotfiles/scripts/checkschildi.sh\"";
      };

      startup = [
        
        { command = "nextcloud --background";}
        { command = "spotify";}
        { command = "discord --start-minimized";}
        { command = "schildichat-desktop --disable-gpu-driver-bug-workarounds --hidden";}
        { command = "ANKI_WAYLAND=1 anki";}
        { command = "OBSIDIAN_USE_WAYLAND=1 obsidian";}
        { command = "nm-applet";}
        
      ];
    };
  };
}
