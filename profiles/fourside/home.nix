{ config, pkgs, lib, ... }: with lib;
{

  wayland.windowManager.sway = {
    config = rec {
      # update for actual inputs here,

      # workspaceOutputAssign = [
      #   { output = "eDP-1"; workspace = "1:一"; }
      #   { output = "DP-4"; workspace = "2:二"; }
      # ];


      keybindings =
        let
          inherit (config.wayland.windowManager.sway.config) modifier;
        in
        {
          "${modifier}+w" = "exec \"bash ~/.dotfiles/scripts/checkelement.sh\"";
          "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
          "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
          "XF86Display" = "exec wl-mirror eDP-1";
          # these are left open to use
          # "XF86WLAN" = "exec wl-mirror eDP-1";
          # "XF86Messenger" = "exec wl-mirror eDP-1";
          # "XF86Go" = "exec wl-mirror eDP-1";
          # "XF86Favorites" = "exec wl-mirror eDP-1";
          # "XF86HomePage" = "exec wtype -P Escape -p Escape";
          # "XF86AudioLowerVolume" = "pactl set-sink-volume alsa_output.pci-0000_08_00.6.HiFi__hw_Generic_1__sink -5%";
          # "XF86AudioRaiseVolume" = "pactl set-sink-volume alsa_output.pci-0000_08_00.6.HiFi__hw_Generic_1__sink +5%  ";
          "XF86AudioMute" = "pactl set-sink-mute alsa_output.pci-0000_08_00.6.HiFi__hw_Generic_1__sink toggle";
        };

    };
  };
}
