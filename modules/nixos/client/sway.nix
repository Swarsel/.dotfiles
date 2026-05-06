{ lib, config, pkgs, withHomeManager, ... }:
let
  inherit (config.swarselsystems) mainUser;
in
{
  config =
    {
      programs.sway = {
        enable = true;
        package = pkgs.swayfx;
        wrapperFeatures = {
          base = true;
          gtk = true;
        };
      };
    } // lib.optionalAttrs withHomeManager {
      inherit (config.home-manager.users.${mainUser}.wayland.windowManager.sway) extraSessionCommands;
    };
}
