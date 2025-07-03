{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.distrobox = lib.mkEnableOption "distrobox config";
  config = lib.mkIf config.swarselsystems.modules.distrobox {
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
