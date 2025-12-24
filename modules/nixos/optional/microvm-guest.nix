{ self, inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.impermanence.nixosModules.impermanence
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.microvm.nixosModules.host
    inputs.microvm.nixosModules.microvm
    inputs.nix-index-database.nixosModules.nix-index
    inputs.nix-minecraft.nixosModules.minecraft-servers
    inputs.nix-topology.nixosModules.default
    inputs.nswitch-rcm-nix.nixosModules.nswitch-rcm
    inputs.simple-nixos-mailserver.nixosModules.default
    inputs.sops.nixosModules.sops
    inputs.stylix.nixosModules.stylix
    inputs.swarsel-nix.nixosModules.default
    inputs.nixos-nftables-firewall.nixosModules.default

    (inputs.nixos-extra-modules + "/modules/interface-naming.nix")

    "${self}/modules/shared/meta.nix"
  ];

  config = {
    system.stateVersion = "23.05";
  };
}
