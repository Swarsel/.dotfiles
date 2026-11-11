let
  settings =
    pkgs:
    let
      proportional = {
        # package = (pkgs.nerdfonts.override { fonts = [ "FiraMono" "FiraCode"]; });
        # package = pkgs.cantarell-fonts;
        # package = pkgs.montserrat;
        # name = "Cantarell";
        package = pkgs.iosevka-bin.override { variant = "Aile"; };
        name = "Iosevka Aile";
        # name = "FiraCode Nerd Font Propo";
        # name = "Montserrat";
      };
    in
    {
      base16Scheme = {
        base00 = "1d252c";
        base01 = "171d23";
        base02 = "206a86";
        base03 = "003a66";
        base04 = "5ec4ff";
        base05 = "a0b3c5";
        base06 = "7ed4ff";
        base07 = "8ef4ff";
        base08 = "d95468";
        base09 = "ffa880";
        base0A = "6ed4ff";
        base0B = "8bd49c";
        base0C = "008b94";
        base0D = "5ec4ff";
        base0E = "c06ece";
        base0F = "3c0044";
      };
      cursor = {
        package = pkgs.banana-cursor;
        # package = pkgs.capitaine-cursors;
        name = "Banana";
        # name = "capitaine-cursors";
        size = 16;
      };
      fonts = {
        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
        monospace = {
          package = pkgs.nerd-fonts.fira-code; # has overrides
          name = "FiraCode Nerd Font";
        };
        sansSerif = proportional;
        serif = proportional;
        sizes = {
          applications = 11;
          terminal = 10;
        };
      };
      opacity.popups = 0.5;
      polarity = "dark";
    };
in
{
  flake-file.inputs.stylix = {
    inputs = {
      flake-parts.follows = "flake-parts";
      nixpkgs.follows = "nixpkgs";
      nur.follows = "nur";
      systems.follows = "systems";
    };
    url = "github:danth/stylix";
  };

  flake.modules = {
    homeManager.stylix =
      {
        inputs,
        lib,
        arch,
        type,
        ...
      }:
      {
        imports = lib.optionals (inputs ? stylix) (
          lib.optionals (type != "nixos") [ inputs.stylix.homeModules.stylix ]
          ++ [
            (
              {
                config,
                lib,
                pkgs,
                nixosConfig ? null,
                ...
              }:
              {
                swarselsystems.enabledHomeModules = [ "stylix" ];
                gtk.gtk4.theme = lib.mkForce config.gtk.theme;
                home.pointerCursor.enable = true;
                stylix = {
                  targets = {
                    emacs.enable = false;
                    rofi.enable = false;
                    spicetify.enable = arch != "aarch64-linux";
                  };
                }
                // lib.optionalAttrs (nixosConfig == null) (
                  lib.recursiveUpdate {
                    enable = true;
                  } (settings pkgs)
                );
              }
            )
          ]
        );
      };
    nixos.stylix = { inputs, lib, ... }: {
      imports = lib.optionals (inputs ? stylix) [
        inputs.stylix.nixosModules.stylix
        (
          {
            config,
            lib,
            pkgs,
            ...
          }:
          {
            stylix = lib.recursiveUpdate {
              enable = true;
              image = config.swarselsystems.wallpaper;
              targets.grub.enable = false; # the styling makes grub more ugly
            } (settings pkgs);
          }
        )
      ];
    };
  };
}
