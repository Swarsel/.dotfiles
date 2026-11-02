{
  flake.modules = {
    homeManager = {
      programs = { self, ... }: {
        imports = [ self.modules.homeManager.cli-programs ];
        config = {
          swarselsystems.enabledHomeModules = [ "programs" ];
          programs = {
            imv.enable = true;
            mpv.enable = true;
            pandoc.enable = true;
            rclone.enable = true;
            yt-dlp.enable = true;
          };
        };
      };
      cli-programs = {
        swarselsystems.enabledHomeModules = [ "cli-programs" ];
        programs = {
          bat.enable = true;
          bottom.enable = true;
          carapace.enable = true;
          fzf = {
            enable = true;
            enableBashIntegration = false;
            enableZshIntegration = false;
          };
          jq.enable = true;
          less.enable = true;
          lesspipe.enable = true;
          ripgrep.enable = true;
          zoxide = {
            options = [
              "--cmd cd"
            ];
            enable = true;
            enableZshIntegration = true;
          };
        };
        home.sessionVariables._ZO_EXCLUDE_DIRS = "$HOME:$HOME/.ansible/*:$HOME/test/*:/persist";
      };
    };
    nixos.programs.config.programs = {
      dconf.enable = true;
      evince.enable = true;
      kdeconnect.enable = true;
    };
  };
}
