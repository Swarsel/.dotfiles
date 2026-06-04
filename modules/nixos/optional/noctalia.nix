{ inputs, lib, ... }:
{
  flake-file.inputs.noctoggle.url = "github:Swarsel/noctoggle";

  imports = lib.optionals (inputs ? noctoggle) [
    inputs.noctoggle.nixosModules.default
    ({ self, inputs, config, ... }: {
      disabledModules = [ "programs/gpu-screen-recorder.nix" ];
      imports = [
        "${inputs.nixpkgs-dev}/nixos/modules/programs/gpu-screen-recorder.nix"
      ];
      home-manager.users.${config.swarselsystems.mainUser}.imports = [
        "${self}/modules/home/optional/noctalia.nix"
      ];
      services = {
        upower.enable = true; # needed for battery percentage
        gnome.evolution-data-server = {
          enable = false; # needed for calendar integration
        };

        noctoggle = {
          enable = true;
          # noctaliaPackage = pkgs.noctalia-shell;
        };

      };
      programs = {
        gpu-screen-recorder.enable = true;
        evolution.enable = false;
      };
    })
  ];
}
