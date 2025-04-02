{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.programs = lib.mkEnableOption "programs settings";
  config = lib.mkIf config.swarselsystems.modules.programs {
    programs = {
      bottom.enable = true;
      imv.enable = true;
      sioyek.enable = true;
      bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];
      };
      carapace.enable = true;
      wlogout.enable = true;
      swayr.enable = true;
      yt-dlp.enable = true;
      mpv.enable = true;
      jq.enable = true;
      ripgrep.enable = true;
      pandoc.enable = true;
      fzf.enable = true;
      zoxide.enable = true;
    };
  };
}
