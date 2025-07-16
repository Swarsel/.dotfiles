{ lib, config, pkgs, ... }:
{
  options.swarselmodules.distrobox = lib.mkEnableOption "distrobox config";
  config = lib.mkIf config.swarselmodules.distrobox {
    environment.systemPackages = with pkgs; [
      distrobox
      boxbuddy
    ];

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      package = pkgs.stable.podman;
    };
  };
}
