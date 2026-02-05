{ self, inputs, config, pkgs, ... }:
{
  imports = [
    inputs.niri-flake.nixosModules.niri
  ];
  config = {

    niri-flake.cache.enable = true;
    home-manager.users.${config.swarselsystems.mainUser}.imports = [
      "${self}/modules/home/optional/niri.nix"
    ];

    environment.systemPackages = with pkgs; [
      wl-clipboard
      wayland-utils
      libsecret
      cage
      gamescope
      xwayland-satellite-unstable
    ];


    programs = {
      niri = {
        enable = true;
        package = pkgs.niri-stable; # the actual niri that will be installed and used
      };
    };
  };
}
