{ lib, config, pkgs, ... }:
{
  options.swarselmodules.programs = lib.mkEnableOption "programs settings";
  config = lib.mkIf config.swarselmodules.programs {
    programs = {
      bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];
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
      wlogout.enable = true;
      yt-dlp.enable = true;
      zoxide = {
        enable = true;
        enableZshIntegration = true;
        options = [
          "--cmd cd"
        ];
      };
    };
  };
}
