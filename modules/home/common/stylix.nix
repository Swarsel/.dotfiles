{ self, lib, config, vars, ... }:
{
  config = {
    swarselsystems.enabledHomeModules = [ "stylix" ];
    gtk.gtk4.theme = lib.mkForce config.gtk.theme;
    stylix = {
      targets = vars.stylixHomeTargets;
    } // lib.optionalAttrs (!config.swarselsystems.isNixos) (lib.recursiveUpdate
      {
        enable = true;
        base16Scheme = "${self}/files/stylix/swarsel.yaml";
      }
      vars.stylix);
  };
}
