{ lib, config, pkgs, ... }:
let
  inherit (config.swarselsystems) mainUser;
in
{
  options.swarselmodules.sway = lib.mkEnableOption "sway config";
  config = lib.mkIf config.swarselmodules.sway {
    programs.sway = {
      enable = true;
      package = pkgs.swayfx;
      wrapperFeatures = {
        base = true;
        gtk = true;
      };

      inherit (config.home-manager.users.${mainUser}.wayland.windowManager.sway) extraSessionCommands;
    };
  };
}
