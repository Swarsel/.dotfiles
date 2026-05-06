{ self, lib, config, vars, ... }:
{
  config = {
    stylix = lib.recursiveUpdate
      {
        enable = true;
        base16Scheme = "${self}/files/stylix/swarsel.yaml";
        targets.grub.enable = false; # the styling makes grub more ugly
        image = config.swarselsystems.wallpaper;
      }
      vars.stylix;
  };
}
