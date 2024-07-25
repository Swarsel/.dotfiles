{ config, pkgs, lib, ... }: with lib;
{

  wayland.windowManager.sway = {
    config = rec {
      # update for actual inputs here,

      # workspaceOutputAssign = [
      #   { output = "eDP-1"; workspace = "1:一"; }
      #   { output = "DP-4"; workspace = "2:二"; }
      # ];



    };
  };
}
