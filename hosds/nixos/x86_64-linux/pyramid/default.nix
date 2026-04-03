{ self, inputs, ... }:
{

  imports = [
    inputs.nixos-hardware.nixosModules.framework-16-7040-amd

    ./disk-config.nix
    ./hardware-configuration.nix

    # "${self}/modules-clone/nixos/optional/amdcpu.nix"
    # "${self}/modules-clone/nixos/optional/amdgpu.nix"
    # "${self}/modules-clone/nixos/optional/framework.nix"
    # "${self}/modules-clone/nixos/optional/gaming.nix"
    "${self}/modules-clone/nixos/optional/hibernation.nix"
    # "${self}/modules-clone/nixos/optional/nswitch-rcm.nix"
    # "${self}/modules-clone/nixos/optional/virtualbox.nix"
    # "${self}/modules/nixos/optional/work.nix"
    # "${self}/modules/nixos/optional/niri.nix"
    # "${self}/modules/nixos/optional/noctalia.nix"
  ];
}
