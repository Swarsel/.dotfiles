{ inputs, ... }:
{
  flake-file = {
    description = "SwarseFlake - Nix Flake for all SwarselSystems";
    inputs = {
      flake-file.url = "github:vic/flake-file";

      flake-parts = {
        inputs.nixpkgs-lib.follows = "nixpkgs";
        url = "github:hercules-ci/flake-parts";
      };

      flake-utils = {
        inputs.systems.follows = "systems";
        url = "github:numtide/flake-utils";
      };

      home-manager = {
        # url = "github:Swarsel/home-manager/main";
        inputs.nixpkgs.follows = "nixpkgs";
        url = "github:nix-community/home-manager";
      };

      import-tree.url = "github:vic/import-tree";

      nixos-extra-modules = {
        inputs = {
          devshell.follows = "devshell";
          flake-parts.follows = "flake-parts";
          nixpkgs.follows = "nixpkgs";
          pre-commit-hooks.follows = "pre-commit-hooks";
        };
        url = "github:Swarsel/nixos-extra-modules/dev";
      };

      nixos-hardware = {
        inputs.nixpkgs.follows = "nixpkgs";
        url = "github:NixOS/nixos-hardware/master";
      };

      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      nixpkgs-dev.url = "github:Swarsel/nixpkgs/main";
      nixpkgs-kernelpin.url = "github:nixos/nixpkgs/31ecbaca1bdefa45dffc409f0250bd8039ea0010?narHash=sha256-dhoW6VgFWlaodSY5jrBn%2BCF2FLmaUvDVgM7%2BC7T2%2BNM%3D";
      nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
      nixpkgs-stable24_11.url = "github:NixOS/nixpkgs/nixos-24.11";
      nixpkgs-stable25_05.url = "github:NixOS/nixpkgs/nixos-25.05";
      nixpkgs-stable26_05.url = "github:NixOS/nixpkgs/nixos-26.05";

      swarsel-nix = {
        inputs = {
          flake-parts.follows = "flake-parts";
          nixpkgs.follows = "nixpkgs";
          systems.follows = "systems";
        };
        url = "github:Swarsel/swarsel-nix/main";
      };

      systems.url = "github:nix-systems/default";
    };
    outputs = "inputs: import ./modules/flake/_outputs.nix inputs";
  };

  imports = [
    inputs.flake-file.flakeModules.default
  ];
}
