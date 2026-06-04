{ inputs, lib, ... }:
{
  flake-file.inputs.niritiling.url = "github:Swarsel/niritiling/feat/resize";

  imports = lib.optionals (inputs ? niritiling) [
    inputs.niri-flake.nixosModules.niri
    inputs.niritiling.nixosModules.default
    ({ self, config, pkgs, ... }: {
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

      services.niritiling = {
        enable = true;
        resizeColumns = true;
      };

      programs = {
        niri = {
          enable = true;
          package = pkgs.niri-stable;
        };
      };
    })
  ];
}
