{ inputs, lib, arch, type, ... }:
{
  flake-file.inputs.stylix = lib.mkDefault { url = "github:danth/stylix"; };

  imports = lib.optionals (inputs ? stylix) (
    lib.optionals (type != "nixos") [ inputs.stylix.homeModules.stylix ] ++ [
      ({ self, lib, config, vars, ... }: {
        swarselsystems.enabledHomeModules = [ "stylix" ];
        gtk.gtk4.theme = lib.mkForce config.gtk.theme;
        stylix = {
          targets = vars.stylixHomeTargets // {
            spicetify.enable = if (arch == "aarch64-linux") then false else true;
          };
        } // lib.optionalAttrs (!config.swarselsystems.isNixos) (lib.recursiveUpdate
          {
            enable = true;
            base16Scheme = "${self}/files/stylix/swarsel.yaml";
          }
          vars.stylix);
      })
    ]
  );
}
