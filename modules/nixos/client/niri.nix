{ lib, config, pkgs, ... }:
let
  moduleName = "niri";
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "${moduleName} settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {

    environment.systemPackages = with pkgs; [
      wl-clipboard
      wayland-utils
      libsecret
      cage
      gamescope
      xwayland-satellite-unstable
    ];

    niri-flake.cache.enable = true;

    programs.niri = {
      enable = true;
      package = pkgs.niri-unstable; # the actual niri that will be installed and used
    };
  };
}
