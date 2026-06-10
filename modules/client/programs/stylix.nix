{
  # flake-file.inputs.stylix.url = "github:danth/stylix";
  flake-file.inputs.stylix.url = "github:Swarsel/stylix/feat/noctalia-v5";

  flake.modules = {
    nixos.stylix = { inputs, lib, ... }: {
      imports = lib.optionals (inputs ? stylix) [
        inputs.stylix.nixosModules.stylix
        ({ self, lib, config, vars, ... }: {
          stylix = lib.recursiveUpdate
            {
              enable = true;
              base16Scheme = "${self}/files/stylix/swarsel.yaml";
              targets.grub.enable = false; # the styling makes grub more ugly
              image = config.swarselsystems.wallpaper;
            }
            vars.stylix;
        })
      ];
    };

    homeManager.stylix = { inputs, lib, arch, type, ... }: {
      imports = lib.optionals (inputs ? stylix) (
        lib.optionals (type != "nixos") [ inputs.stylix.homeModules.stylix ] ++ [
          ({ self, lib, config, vars, nixosConfig ? null, ... }: {
            swarselsystems.enabledHomeModules = [ "stylix" ];
            gtk.gtk4.theme = lib.mkForce config.gtk.theme;
            stylix = {
              targets = vars.stylixHomeTargets // {
                spicetify.enable = if (arch == "aarch64-linux") then false else true;
              };
            } // lib.optionalAttrs (nixosConfig == null) (lib.recursiveUpdate
              {
                enable = true;
                base16Scheme = "${self}/files/stylix/swarsel.yaml";
              }
              vars.stylix);
          })
        ]
      );
    };
  };
}
