{ inputs, lib, ... }:
{
  flake-file.inputs.stylix.url = "github:danth/stylix";

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
}
