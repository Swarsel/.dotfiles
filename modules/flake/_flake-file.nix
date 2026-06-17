{ inputs, ... }:
{
  imports = [
    inputs.flake-file.flakeModules.default
  ];

  flake-file = {
    description = "SwarseFlake - Nix Flake for all SwarselSystems";
    outputs = "inputs: import ./modules/flake/_outputs.nix inputs";
    inputs = {
      flake-file.url = "github:vic/flake-file";

      flake-parts.url = "github:hercules-ci/flake-parts";
      import-tree.url = "github:vic/import-tree";
      systems.url = "github:nix-systems/default";

      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      nixpkgs-dev.url = "github:Swarsel/nixpkgs/main";
      nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
      nixpkgs-master.url = "github:nixos/nixpkgs/master";
      nixpkgs-kernelpin.url = "github:nixos/nixpkgs/dd9b079222d43e1943b6ebd802f04fd959dc8e61?narHash=sha256-I45esRSssFtJ8p/gLHUZ1OUaaTaVLluNkABkk6arQwE%3D";
      nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
      nixpkgs-stable24_05.url = "github:NixOS/nixpkgs/nixos-24.05";
      nixpkgs-stable24_11.url = "github:NixOS/nixpkgs/nixos-24.11";
      nixpkgs-stable25_05.url = "github:NixOS/nixpkgs/nixos-25.05";
      nixpkgs-stable25_11.url = "github:NixOS/nixpkgs/nixos-25.11";

      home-manager = {
        # url = "github:nix-community/home-manager";
        url = "github:Swarsel/home-manager/main";
        inputs.nixpkgs.follows = "nixpkgs";
      };

      nixos-hardware.url = "github:NixOS/nixos-hardware/master";
      nixos-extra-modules.url = "github:oddlama/nixos-extra-modules/main";

      swarsel-nix.url = "github:Swarsel/swarsel-nix/main";
    };
  };
}
