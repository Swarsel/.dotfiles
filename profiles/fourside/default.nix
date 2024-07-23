{ inputs, outputs, ... }:
{

  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen2
    ./hardware-configuration.nix
    ./nixos.nix
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.users.swarsel.imports = outputs.mixedModules ++ [
        ./home.nix
      ];
    }
  ];

  nixpkgs = {
    overlays = outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

}
