{ self, lib, config, vars, withHomeManager, ... }:
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
  } // lib.optionalAttrs withHomeManager {
    home-manager.users."${config.swarselsystems.mainUser}" = {
      stylix = {
        targets = vars.stylixHomeTargets;
      };
    };
  };
}
