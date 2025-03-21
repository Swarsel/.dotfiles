{ self, lib, pkgs, ... }:
{
  options.swarselsystems = {
    stylix = lib.mkOption {
      type = lib.types.attrs;
      default = {
        enable = true;
        base16Scheme = "${self}/programs/stylix/swarsel.yaml";
        polarity = "dark";
        opacity.popups = 0.5;
        cursor = {
          package = pkgs.banana-cursor;
          # package = pkgs.capitaine-cursors;
          name = "Banana";
          # name = "capitaine-cursors";
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
      };
    };
  };

}
