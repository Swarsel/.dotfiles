{ config, pkgs, lib, fetchFromGitHub, ... }:

{
  programs.home-manager.enable = true;
  home.username = "leons";
  home.homeDirectory = "/home/leons";

  home.stateVersion = "23.05"; # Please read the comment before changing.

   stylix.image = ../../wallpaper/surfacewp.png;
  
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
  
  
  

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };
  services.xcape = {
    enable = true;
    mapExpression = {
      Control_L = "Escape";
    };
  };
  #keyboard config
  home.keyboard.layout = "us";

  sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/sops" ];

  # waybar config
  programs.waybar.settings.mainBar.cpu.format = "{icon0} {icon1} {icon2} {icon3}";

  programs.waybar.settings.mainBar.temperature.hwmon-path = "/sys/devices/platform/coretemp.0/hwmon/hwmon3/temp3_input";
  programs.waybar.settings.mainBar.modules-right = ["custom/outer-left-arrow-dark" "mpris" "custom/left-arrow-light"
                                                    "network"
                                                    "custom/left-arrow-dark"
                                                    "pulseaudio"
                                                    "custom/left-arrow-light"
                                                    "battery"
                                                    "custom/left-arrow-dark"
                                                    "temperature"
                                                    "custom/left-arrow-light"
                                                    "disk"
                                                    "custom/left-arrow-dark"
                                                    "memory"
                                                    "custom/left-arrow-light"
                                                    "cpu"
                                                    "custom/left-arrow-dark"
                                                    "tray"
                                                    "custom/left-arrow-light"
                                                    "clock#2"
                                                    "custom/left-arrow-dark"
                                                    "clock#1" ];
  services.blueman-applet.enable = true;
  home.packages = with pkgs; [
    # nixgl.auto.nixGLDefault
    evince
    # nodejs_20

    # messaging
    # we use gomuks for RAM preservation, but keep schildi around for files and images
  ];

  programs.zsh.initExtra = "
export GPG_TTY=\"$(tty)\"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent
      ";

  # sway config
  wayland.windowManager.sway= {
    config = rec {
      input = {
        "*" = {
          xkb_layout = "us";
          xkb_options = "ctrl:nocaps,grp:win_space_toggle";
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
        "${modifier}+Ctrl+p" = "exec nixGL wl-mirror eDP-1";
        "${modifier}+t" = "exec sway output eDP-1 transform 90, splitv";
        "${modifier}+XF86AudioLowerVolume" = "exec grim -g \"$(slurp)\" -t png - | wl-copy -t image/png";
        "${modifier}+XF86AudioRaiseVolume" = "exec grim -g \"$(slurp)\" -t png - | wl-copy -t image/png";
        "${modifier}+w" = "exec \"bash ~/.dotfiles/scripts/checkgomuks.sh\"";
      };

      startup = [
        { command = "sleep 60 && nixGL nextcloud --background";}
        # { command = "sleep 60 && nixGL spotify";}
        { command = "sleep 60 && nixGL discord --start-minimized -enable-features=UseOzonePlatform -ozone-platform=wayland";}
        # { command = "sleep 60 && nixGL schildichat-desktop --hidden";}
        { command = "sleep 60 && nixGL syncthingtray --wait"; }
        { command = "sleep 60 && ANKI_WAYLAND=1 nixGL anki";}
        { command = "nm-applet --indicator";}
        { command = "sleep 60 && OBSIDIAN_USE_WAYLAND=1 nixGL obsidian -enable-features=UseOzonePlatform -ozone-platform=wayland";}
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
