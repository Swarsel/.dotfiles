{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    distrobox
    boxbuddy
  ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    package = pkgs.stable.podman;
  };

}
