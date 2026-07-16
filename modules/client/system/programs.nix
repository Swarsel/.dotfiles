{
  flake.modules = {
    homeManager.programs = { pkgs, ... }: {
      config = {
        swarselsystems.enabledHomeModules = [ "programs" ];
        programs = {
          bat = {
            enable = true;
            extraPackages = [
              pkgs.bat-extras.batdiff
              pkgs.bat-extras.batman
              pkgs.bat-extras.batwatch
              pkgs.bat-extras.batgrep
            ];
          };
          bottom.enable = true;
          carapace.enable = true;
          fzf = {
            enable = true;
            enableBashIntegration = false;
            enableZshIntegration = false;
          };
          imv.enable = true;
          jq.enable = true;
          less.enable = true;
          lesspipe.enable = true;
          mpv.enable = true;
          pandoc.enable = true;
          rclone.enable = true;
          ripgrep.enable = true;
          sioyek.enable = true;
          swayr.enable = true;
          timidity.enable = true;
          wlogout = {
            enable = true;
            layout = [
              {
                action = "loginctl lock-session";
                circular = true;
                keybind = "l";
                label = "lock";
                text = "Lock";
              }
              {
                action = "systemctl hibernate";
                circular = true;
                keybind = "h";
                label = "hibernate";
                text = "Hibernate";
              }
              {
                action = "loginctl terminate-user $USER";
                circular = true;
                keybind = "u";
                label = "logout";
                text = "Logout";
              }
              {
                action = "systemctl poweroff";
                circular = true;
                keybind = "p";
                label = "shutdown";
                text = "Shutdown";
              }
              {
                action = "systemctl suspend";
                circular = true;
                keybind = "s";
                label = "suspend";
                text = "Suspend";
              }
              {
                action = "systemctl reboot";
                circular = true;
                keybind = "r";
                label = "reboot";
                text = "Reboot";
              }
            ];
          };
          yt-dlp.enable = true;
          zoxide = {
            options = [
              "--cmd cd"
            ];
            enable = true;
            enableZshIntegration = true;
          };
        };
        home.sessionVariables = {
          _ZO_EXCLUDE_DIRS = "$HOME:$HOME/.ansible/*:$HOME/test/*:/persist";
        };
      };
    };
    nixos.programs = {
      config = {
        programs = {
          dconf.enable = true;
          evince.enable = true;
          kdeconnect.enable = true;
        };
      };
    };
  };
}
