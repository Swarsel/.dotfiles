{ self, lib, config, ... }:
{
  options.swarselsystems.modules.stylix = lib.mkEnableOption "stylix config";
  config = {
    stylix = {
      enable = true;
      base16Scheme = "${self}/files/stylix/swarsel.yaml";
    } // lib.optionalAttrs config.swarselsystems.modules.stylix
      (lib.recursiveUpdate
        {
          targets.grub.enable = false; # the styling makes grub more ugly
          image = config.swarselsystems.wallpaper;
        }
        config.swarselsystems.stylix);
    home-manager.users."${config.swarselsystems.mainUser}" = {
      stylix = {
        targets = config.swarselsystems.stylixHomeTargets;
      };
    };
  };
}
