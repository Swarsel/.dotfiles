{ self, lib, config, pkgs, ... }:
{
  stylix = lib.mkIf (!config.swarselsystems.isNixos) {

    enable = true;
    base16Scheme = "${self}/wallpaper/swarsel.yaml";
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
        package = pkgs.nerd-fonts.fira-mono; # has overrides

        name = "FiraCode Nerd Font Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };

    image = config.swarselsystems.wallpaper;
    targets = {
      emacs.enable = false;
      waybar.enable = false;
    };
  };
}
