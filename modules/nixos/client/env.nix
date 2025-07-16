{ lib, config, pkgs, ... }:
{
  options.swarselmodules.env = lib.mkEnableOption "environment config";
  config = lib.mkIf config.swarselmodules.env {

    environment = {
      wordlist.enable = true;
      sessionVariables = {
        NIXOS_OZONE_WL = "1";
        GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-libav
        ]);
      };
    };
  };
}
