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
                self,
                config,
                lib,
                vars,
                nixosConfig ? null,
                ...
              }:
              {
                swarselsystems.enabledHomeModules = [ "stylix" ];
                gtk.gtk4.theme = lib.mkForce config.gtk.theme;
                home.pointerCursor.enable = lib.mkIf (config.stylix.enable && config.stylix.cursor != null) true;
                stylix = {
                  targets = vars.stylixHomeTargets // {
                    spicetify.enable = if (arch == "aarch64-linux") then false else true;
                  };
                }
                // lib.optionalAttrs (nixosConfig == null) (
                  lib.recursiveUpdate {
                    enable = true;
                    base16Scheme = "${self}/files/stylix/swarsel.yaml";
                  } vars.stylix
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
            self,
            config,
            lib,
            vars,
            ...
          }:
          {
            stylix = lib.recursiveUpdate {
              enable = true;
              base16Scheme = "${self}/files/stylix/swarsel.yaml";
              image = config.swarselsystems.wallpaper;
              targets.grub.enable = false; # the styling makes grub more ugly
            } vars.stylix;
          }
        )
      ];
    };
  };
}
