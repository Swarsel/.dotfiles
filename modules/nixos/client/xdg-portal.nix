{ lib, config, pkgs, ... }:
{
  options.swarselmodules.xdg-portal = lib.mkEnableOption "xdg portal config";
  config = lib.mkIf config.swarselmodules.xdg-portal {
    xdg.portal = {
      enable = true;
      # config = {
      #   common = {
      #     default = "wlr";
      #   };
      # };
      wlr.enable = true;
      wlr.settings.screencast = {
        output_name = "eDP-1";
        chooser_type = "simple";
        chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
      };
    };
  };
}
