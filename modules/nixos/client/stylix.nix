{ self, lib, config, vars, ... }:
{
  options.swarselmodules.stylix = lib.mkEnableOption "stylix config";
  config = {
    stylix = {
      enable = true;
      base16Scheme = "${self}/files/stylix/swarsel.yaml";
    } // lib.optionalAttrs config.swarselmodules.stylix
      (lib.recursiveUpdate
        {
          targets.grub.enable = false; # the styling makes grub more ugly
          image = config.swarselsystems.wallpaper;
        }
        vars.stylix);
    home-manager.users."${config.swarselsystems.mainUser}" = {
      stylix = {
        targets = vars.stylixHomeTargets;
      };
    };
  };
}
