{ self, inputs, config, ... }:
{
  disabledModules = [ "programs/gpu-screen-recorder.nix" ];
  imports = [
    "${inputs.nixpkgs-dev}/nixos/modules/programs/gpu-screen-recorder.nix"
  ];
  config = {
    home-manager.users.${config.swarselsystems.mainUser}.imports = [
      "${self}/modules/home/optional/noctalia.nix"
    ];
    services = {
      upower.enable = true; # needed for battery percentage
      gnome.evolution-data-server.enable = true; # needed for calendar integration
    };
    programs.gpu-screen-recorder.enable = true;
  };
}
